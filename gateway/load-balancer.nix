{ config, lib, pkgs, ... }:
with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  internalVlanMap = listToAttrs (flip map (calculated.myNetData.vlans ++ [ "lan" ]) (v:
    nameValuePair v vars.internalVlanMap.${v}
  ));

  lbMap = calculated.myNetMap.loadBalancerMap;
  machines = attrNames map;

  lbPrioMap = flip mapAttrs lbMap (lb: _: priorities (orderList lb (attrNames lbMap) (attrValues lbMap)));

  orderList = lb: lbs: machines: if head lbs == lb then machines
    else orderList lb ((tail lbs) ++ [ (head lbs) ]) ((tail machines) ++ [ (head machines) ]);
  priorities = machines: listToAttrs (zipListsWith (machine: prio: nameValuePair machine (256 - prio))
    machines (range 1 (length machines)));
in
{
  services.keepalived = {
    enable = true;
    syncGroups = flip mapAttrs' lbPrioMap (lb: _: nameValuePair "${lb}g" { group = [ "${lb}-4" "${lb}-6" ]; });
    instances = flip mapAttrs' lbPrioMap (lb: priorities: nameValuePair "${lb}-4" {
      interface = "tlan";
      trackInterfaces = [ "wan" ];
      virtualRouterId = calculated.myNetMap.vrrpMap."${lb}-4";
      priority = priorities."${config.networking.hostName}";
      authType = "PASS";
      authPass = "none";
      virtualIpAddresses = [
        { ip = "${calculated.myNetMap.pub4}${toString calculated.myNetMap.pub4MachineMap."${lb}"}/32"; device = "wan"; }
      ];
    }) // flip mapAttrs' lbPrioMap (lb: priorities: nameValuePair "${lb}-6" {
      interface = "tlan";
      trackInterfaces = [ "wan" ];
      virtualRouterId = calculated.myNetMap.vrrpMap."${lb}-6";
      priority = priorities."${config.networking.hostName}";
      authType = "PASS";
      authPass = "none";
      virtualIpAddresses = [
        { ip = "${calculated.myNetMap.pub6}${toString calculated.myNetMap.pub6MachineMap."${lb}"}/128"; device = "wan"; }
      ];
    });
  };
}

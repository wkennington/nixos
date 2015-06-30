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
    instances = flip mapAttrs lbPrioMap (lb: priorities: {
      interface = "tlan";
      trackInterfaces = [ "wan" ];
      virtualRouterId = calculated.myNetMap.pub4MachineMap."${lb}";
      priority = priorities."${config.networking.hostName}";
      authType = "PASS";
      authPass = "none";
      virtualIpAddresses = [
        { ip = "${calculated.myNetMap.pub4}${toString calculated.myNetMap.pub4MachineMap."${lb}"}/32"; device = "wan"; }
      ];
    });
  };
}

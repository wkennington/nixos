{ config, lib, pkgs, ... }:
with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  calculated = (import ../../common/sub/calculated.nix { inherit config lib; });

  internalVlanMap = listToAttrs (flip map (calculated.myNetData.vlans ++ [ "lan" ]) (v:
    nameValuePair v vars.internalVlanMap.${v}
  ));
in
{
  systemd.services.keepalived = {
    path = [ pkgs.iputils pkgs.iproute pkgs.gnugrep pkgs.gnused ];
    preStart = ''
      gateway=""
      while [ -z "$gateway" ]; do
        gateway="$(ip route | grep default | sed -n 's,.*via \([^ ]*\).*,\1,p')"
        sleep 1
      done
      while ! ping -c 1 "$gateway" -W 1; do
        true
      done
    '';
  };

  services.keepalived = {
    enable = true;
    syncGroups.gateway.group = [ "wan" ] ++ attrNames internalVlanMap;
    instances = flip mapAttrs internalVlanMap (n: id: {
      preempt = false;
      interface = "tlan";
      trackInterfaces = [ n ];
      virtualRouterId = id + 1;
      priority = calculated.myNetData.id;
      authType = "PASS";
      authPass = "none";
      virtualIpAddresses = [
        { ip = "${calculated.gatewayIp4 config.networking.hostName n}/32"; device = n; }
      ];
    }) // { wan = {
      preempt = false;
      interface = "tlan";
      trackInterfaces = [ "wan" ];
      virtualRouterId = 254;
      priority = calculated.myNetData.id;
      authType = "PASS";
      authPass = "none";
      virtualIpAddresses = [
        { ip = "${calculated.myNetMap.pub4}${toString calculated.myNetMap.pub4MachineMap.outbound}/32"; device = "wan"; }
        { ip = "${calculated.myNetMap.pub6}${toString calculated.myNetMap.pub6MachineMap.outbound}/64"; device = "wan"; }
      ];
    }; };
  };
}

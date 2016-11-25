{ config, lib, pkgs, ... }:

let
  inherit (lib)
    attrNames
    concatMap
    flip
    length
    listToAttrs
    mapAttrs'
    mkIf
    nameValuePair;

  vars = (import ../../customization/vars.nix { inherit lib; });
  calculated = (import ../../common/sub/calculated.nix { inherit config lib; });

  internalVlanMap = listToAttrs (flip map (calculated.myNetData.vlans ++ [ "lan" ]) (v:
    nameValuePair v vars.internalVlanMap.${v}
  ));
in
mkIf (length calculated.myNetMap.gateways >= 2) {
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
    syncGroups.gateway.group = [ "wan-4" "wan-6" ] ++ concatMap (n: [ "${n}-4" "${n}-6" ]) (attrNames internalVlanMap);
    instances = flip mapAttrs' internalVlanMap (n: id: nameValuePair "${n}-4" {
      preempt = false;
      interface = "tlan";
      trackInterfaces = [ n ];
      virtualRouterId = calculated.myNetMap.vrrpMap."${n}-4";
      priority = calculated.myNetData.id;
      authType = "PASS";
      authPass = "none";
      virtualIpAddresses = [
        { ip = "${calculated.gatewayIp4 config.networking.hostName n}/32"; device = n; }
      ];
    }) // flip mapAttrs' internalVlanMap (n: id: nameValuePair "${n}-6" {
      preempt = false;
      interface = "tlan";
      trackInterfaces = [ n ];
      virtualRouterId = calculated.myNetMap.vrrpMap."${n}-6";
      priority = calculated.myNetData.id;
      authType = "PASS";
      authPass = "none";
      virtualIpAddresses = [
        { ip = "${calculated.gatewayIp6 config.networking.hostName n}/128"; device = n; }
      ];
    }) // {
      "wan-4" = {
        preempt = false;
        interface = "tlan";
        trackInterfaces = [ "wan" ];
        virtualRouterId = calculated.myNetMap.vrrpMap.wan-4;
        priority = calculated.myNetData.id;
        authType = "PASS";
        authPass = "none";
        virtualIpAddresses = [
          { ip = "${calculated.myNetMap.pub4}${toString calculated.myNetMap.pub4MachineMap.outbound}/32"; device = "wan"; }
        ];
      };

      "wan-6" = {
        preempt = false;
        interface = "tlan";
        trackInterfaces = [ "wan" ];
        virtualRouterId = calculated.myNetMap.vrrpMap.wan-6;
        priority = calculated.myNetData.id;
        authType = "PASS";
        authPass = "none";
        virtualIpAddresses = [
          { ip = "${calculated.myNetMap.pub6}${toString calculated.myNetMap.pub6MachineMap.outbound}/128"; device = "wan"; }
        ];
      };
    };
  };
}

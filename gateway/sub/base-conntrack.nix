{ config, lib, pkgs, ... }:

let
  inherit (lib)
    filter;

  calculated = import ../../common/sub/calculated.nix { inherit config lib; };
  otherGateways = filter (n: config.networking.hostName != n) calculated.myNetMap.gateways;
in
{
  environment.systemPackages = [ pkgs.conntrack-tools ];

  services.conntrackd = {
    enable = true;
    interface = "tlan";
    localAddress = calculated.internalIp4 config.networking.hostName "tlan";
    ignoreAddresses = [
      calculated.myVpnIp4
    ] ++ map (vlan: calculated.internalIp4 config.networking.hostName vlan) calculated.myNetData.vlans;
  };

  systemd.services.keepalived = {
    requires = [ "conntrackd.service" ];
    after = [ "conntrackd.service" ];
  };
}

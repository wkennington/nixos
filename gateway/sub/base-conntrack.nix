{ config, lib, pkgs, ... }:

let
  inherit (lib)
    filter;

  calculated = import ../../common/sub/calculated.nix { inherit config lib; };
  otherGateways = filter (n: config.networking.hostName != n) calculated.myNetMap.gateways;
in
{
  environment.systemPackages = [ pkgs.conntrack-tools ];

  networking.firewall.extraCommands = ''
    ip46tables -I INPUT -p udp --dport 3780 -i tlan -j ACCEPT
  '';

  services.conntrackd = {
    enable = true;
    interface = "tlan";
    localAddress = calculated.internalIp4 config.networking.hostName "tlan";
    remoteAddresses = map (n: calculated.internalIp4 n "tlan") otherGateways;
    ignoreAddresses = [
      calculated.myVpnIp4
    ] ++ map (vlan: calculated.internalIp4 config.networking.hostName vlan) calculated.myNetData.vlans;
  };
}

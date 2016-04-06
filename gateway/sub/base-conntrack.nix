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
    iptables -I INPUT -i tlan -d 225.0.0.50 -j ACCEPT
  '';

  services.conntrackd = {
    enable = true;
    interface = "tlan";
    localAddress = calculated.internalIp4 config.networking.hostName "tlan";
    ignoreAddresses = [
      calculated.myVpnIp4
    ] ++ map (vlan: calculated.internalIp4 config.networking.hostName vlan) calculated.myNetData.vlans;
  };

  services.keepalived.syncGroups.gateway = {
    notifyMaster = "${pkgs.conntrack-tools}/libexec/primary-backup.sh primary";
    notifyBackup = "${pkgs.conntrack-tools}/libexec/primary-backup.sh backup";
    notifyFault = "${pkgs.conntrack-tools}/libexec/primary-backup.sh fault";
  };

  systemd.services.keepalived = {
    requires = [ "conntrackd.service" ];
    after = [ "conntrackd.service" ];
    bindsTo = [ "conntrackd.service" ];
    partOf = [ "conntrackd.service" ];
  };
}

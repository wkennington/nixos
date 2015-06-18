{ config, lib, utils, ... }:
with lib;
let
  devices = flip map config.myNatIfs
    (n: "sys-subsystem-net-devices-${utils.escapeSystemdPath n}.device");
in
{
  imports = [
    ../common/sub/base-dnsmasq.nix
  ];

  networking.firewall.extraCommands =
    flip concatMapStrings config.myNatIfs (n: ''
      ip46tables -A INPUT -i ${n} -p udp --dport domain -j ACCEPT
      ip46tables -A INPUT -i ${n} -p tcp --dport domain -j ACCEPT
    '');

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    extraConfig = flip concatMapStrings config.myNatIfs (n: ''
      interface=${n}
      no-dhcp-interface=${n}
    '');
  };

  systemd.services.dnsmasq = {
    after = devices;
    bindsTo = devices;
  };
}

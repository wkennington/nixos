{ config, lib, ... }:
with lib;
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
}

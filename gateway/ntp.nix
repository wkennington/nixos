{ config, lib, ... }:
with lib;
{
  networking.firewall.extraCommands =
    flip concatMapStrings config.myNatIfs (n: ''
      ip46tables -A INPUT -i ${n} -p udp --dport domain -j ACCEPT
      ip46tables -A INPUT -i ${n} -p tcp --dport domain -j ACCEPT
    '');

  services.openntpd.extraConfig = ''
    listen on *
  '';
}

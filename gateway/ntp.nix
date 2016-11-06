{ config, lib, ... }:

with lib;
{
  networking.firewall.extraCommands =
    flip concatMapStrings config.myNatIfs (n: ''
      ip46tables -A INPUT -i ${n} -p udp --dport ntp -j ACCEPT
      ip46tables -A INPUT -i ${n} -p tcp --dport ntp -j ACCEPT
    '');

  services.chrony.extraConfig = ''
    allow 0.0.0.0/0
    allow ::/0
  '';
}

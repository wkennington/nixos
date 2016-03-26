{ config, lib, ... }:
with lib;
{
  assertions = [
    {
      assertion = config.services.unbound.enable || config.services.dnsmasq.enable;
      message = "You must enable at least one of `unbound` or `dnsmasq`";
    }
  ];
  networking.firewall.extraCommands =
    flip concatMapStrings config.myNatIfs (n: ''
      ip46tables -A INPUT -i ${n} -p udp --dport domain -j ACCEPT
      ip46tables -A INPUT -i ${n} -p tcp --dport domain -j ACCEPT
    '');

  services.dnsmasq.extraConfig =
    mkIf (config.services.dnsmasq.enable)
      (flip concatMapStrings config.myNatIfs (n: ''
        interface=${n}
        no-dhcp-interface=${n}
      ''));

  services.unbound.extraConfig = ''
    server:
      prefetch: yes
      prefetch-key: yes
  '';
}

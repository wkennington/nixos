{ ... }:
{
  services = {
    ntp.enable = false;
    openntpd.enable = true;
  };
  networking.firewall.extraCommands = ''
    ip46tables -A OUTPUT -m owner --uid-owner ntp -p udp --dport ntp -j ACCEPT
  '';
}

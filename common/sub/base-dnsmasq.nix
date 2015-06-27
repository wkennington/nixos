{ config, ... }:
{
  networking.firewall.extraCommands = ''
    # Allow dnsmasq to access dns servers
    ip46tables -A OUTPUT -m owner --uid-owner dnsmasq -p udp --dport domain -j ACCEPT
    ip46tables -A OUTPUT -m owner --uid-owner dnsmasq -p tcp --dport domain -j ACCEPT

    # Allow all users to access dns
    ip46tables -A OUTPUT -o lo -p udp --dport domain -j ACCEPT
    ip46tables -A OUTPUT -o lo -p tcp --dport domain -j ACCEPT
  '';

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    extraConfig = ''
      domain-needed
      bogus-priv
      filterwin2k

      # Always reload when hosts change
      no-hosts
      addn-hosts=${config.environment.etc.hosts.source}

      interface=lo
      no-dhcp-interface=lo

      bind-dynamic

      expand-hosts
    '';
  };
}

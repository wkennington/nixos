{ config, lib, pkgs, ... }:
with lib;
let
  trustAnchor = readFile (pkgs.stdenv.mkDerivation {
    name = "dnssec-anchor-dnsmasq";
    builder = pkgs.writeText "builder.sh" ''
      ${pkgs.gawk}/bin/awk '
      {
        if (/Domain:/) { domain=$2; }
        if (/Id:/) { id=$2; }
        if (/Algorithm:/) { algorithm=$2; }
        if (/HashType:/) { hashtype=$2; }
        if (/Hash:/) { hash=$2; }
      }
      END {
        print domain "," id "," algorithm "," hashtype "," hash;
      }
      ' "${pkgs.dnssec-root}/share/dnssec/iana-root.txt" > $out
    '';
  });
in
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

      # Enable Dnssec (disable for now until better resolvers can be added)
      #dnssec
      #trust-anchor=${trustAnchor}
      #dnssec-check-unsigned
      #dnssec-timestamp=/var/lib/dnsmasq/timestamp

      interface=lo
      no-dhcp-interface=lo

      bind-dynamic

      expand-hosts
    '' + concatStrings (flip mapAttrsToList config.myDns.forwardZones (zone: servers:
      flip concatMapStrings servers ({ server, port }: ''
        server=/${zone}/${server}#${port}
      '')
    ));
  };

  systemd.services.dnsmasq.preStart = ''
    mkdir -p /var/lib/dnsmasq
    chmod 0700 /var/lib/dnsmasq
    chown dnsmasq /var/lib/dnsmasq
  '';
}

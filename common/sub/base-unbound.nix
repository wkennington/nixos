{ config, lib, ... }:
let
  cores = config.nix.maxJobs;
  pwr = num:
    if num < 2 then
      1
    else
      (pwr (builtins.div num 2))*2;
  p2cores =
    let
      p2bottom = pwr cores;
    in if p2bottom < cores then p2bottom*2 else p2bottom;
in
with lib;
{
  # Make sure we always use unbound
  networking.hasLocalResolver = true;

  networking.firewall.extraCommands = ''
    # Allow unbound to access dns servers
    ip46tables -A OUTPUT -m owner --uid-owner unbound -p udp --dport domain -j ACCEPT
    ip46tables -A OUTPUT -m owner --uid-owner unbound -p tcp --dport domain -j ACCEPT

    # Allow all users to access dns
    ip46tables -A OUTPUT -o lo -p udp --dport domain -j ACCEPT
    ip46tables -A OUTPUT -o lo -p tcp --dport domain -j ACCEPT
  '';

  services.unbound = {
    enable = true;
    extraConfig = concatStrings (flip mapAttrsToList config.myDns.forwardZones (name: servers:
      "forward-zone:\n  name: ${name}\n" + flip concatMapStrings servers ({ server, port }:
        "  forward-addr: \"${server}@${toString port}\"\n"
      )
    )) + ''
      server:
        num-threads:  ${toString cores}
        msg-cache-slabs: ${toString p2cores}
        rrset-cache-slabs: ${toString p2cores}
        infra-cache-slabs: ${toString p2cores}
        key-cache-slabs: ${toString p2cores}
        rrset-cache-size: 100m
        msg-cache-size: 50m
        outgoing-range: 8192
        num-queries-per-thread: 4096
        so-rcvbuf: 4m
        so-sndbuf: 4m
        so-reuseport: yes

        interface: 0.0.0.0
        interface: ::0
        access-control: 0.0.0.0/0 allow
      remote-control:
        control-enable: yes
        control-use-cert: no
    '';
  };

  myDns.forwardZones' = attrNames config.myDns.forwardZones;
}

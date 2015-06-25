{ config, lib, ... }:
with lib;
{
  networking.firewall.extraCommands = mkOrder 2 ''
    # Forward Outbound Connections
    ${concatStrings (map (n: ''
      ip46tables -w -A FORWARD -i ${n} -o wan -j ACCEPT
      ip46tables -w -A FORWARD -i ${n} -o gwan -j ACCEPT
      ip6tables -w -A FORWARD -i ${n} -o hurricane -j ACCEPT
      ip46tables -A FORWARD -i ${n} -o tinc.vpn -j ACCEPT
    '') (filter (n: n != "tinc.vpn") config.myNatIfs))}

    # Masquerade all private connections
    iptables -t mangle -A PREROUTING -m set --match-set private src -j MARK --set-mark 0x10
    iptables -t nat -A POSTROUTING -m mark --mark 0x10 -j MASQUERADE

    # Allow access to servers
    ${concatStrings (map (n: ''
      ip46tables -A FORWARD -i ${n} -o slan -j ACCEPT
    '') (filter (n: n != "slan") config.myNatIfs))}
  '';
}

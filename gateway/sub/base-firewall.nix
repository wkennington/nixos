{ config, lib, ... }:
with lib;
let
  calculated = (import ../../common/sub/calculated.nix { inherit config lib; });

  natval = let
    outboundOrNull = calculated.myNetMap.pub4MachineMap.outbound or null;
    pub4OrNull = calculated.myNetMap.pub4 or null;
  in if outboundOrNull == null || pub4OrNull == null then "MASQUERADE" else "SNAT --to ${pub4OrNull}${toString outboundOrNull}";
in
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
    #iptables -t nat -A POSTROUTING -m mark --mark 0x10 -j MASQUERADE

    # Masquerade all public connections
    iptables -t nat -A POSTROUTING -o wan -m mark --mark 0x10 -j ${natval}
    iptables -t nat -A POSTROUTING -o gwan -m mark --mark 0x10 -j ${natval}

    # Allow access to servers
    ${concatStrings (map (n: ''
      ip46tables -A FORWARD -i ${n} -o slan -j ACCEPT
    '') (filter (n: n != "slan") config.myNatIfs))}
  '';
}

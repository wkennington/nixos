{ config, lib, ... }:
with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  calculated = (import ../../common/sub/calculated.nix { inherit config lib; });

  natval = let
    outboundOrNull = calculated.myNetMap.pub4MachineMap.outbound or null;
    pub4OrNull = calculated.myNetMap.pub4 or null;
  in if outboundOrNull == null || pub4OrNull == null then "MASQUERADE" else "SNAT --to ${pub4OrNull}${toString outboundOrNull}";

  nat6val = let
    outboundOrNull = calculated.myNetMap.pub6MachineMap.outbound or null;
    pub6OrNull = calculated.myNetMap.pub6 or null;
  in if outboundOrNull == null || pub6OrNull == null then "MASQUERADE" else "SNAT --to ${pub6OrNull}${toString outboundOrNull}";
in
{
  networking.firewall.extraCommands = mkOrder 2 ''
    # Forward Outbound Connections
    ${concatStrings (map (n: ''
      ip46tables -w -A FORWARD -i ${n} -o wan -j ACCEPT
      ip46tables -w -A FORWARD -i ${n} -o gwan -j ACCEPT
      ip6tables -w -A FORWARD -i ${n} -o hurricane -j ACCEPT
      ip46tables -A FORWARD -i ${n} -o ${vars.domain}.vpn -j ACCEPT
      ip46tables -A FORWARD -i ${n} -o gw.${vars.domain}.vpn -j ACCEPT
    '') (filter (n: n != "${vars.domain}.vpn") config.myNatIfs))}

    # Masquerade all private connections
    iptables -t mangle -A PREROUTING -m set --match-set private src -j MARK --set-mark 0x10
    ip6tables -t mangle -A PREROUTING -m set --match-set private6 src -j MARK --set-mark 0x10
    #iptables -t nat -A POSTROUTING -m mark --mark 0x10 -j MASQUERADE

    # Masquerade all vpn connections
    # If we hit a node with vpn support we might have asymmetric routing otherwise.
    #iptables -t mangle -A PREROUTING -s "${vars.vpn.subnet4}0/24" -j MARK --set-mark 0x11
    #iptables -t mangle -A PREROUTING -s "${vars.vpn.remote4}0/24" -j MARK --set-mark 0x11
    #iptables -t nat -A POSTROUTING -m mark --mark 0x11 -j MASQUERADE

    # Masquerade all public connections
    iptables -t nat -A POSTROUTING -o wan -m mark --mark 0x10 -j ${natval}
    iptables -t nat -A POSTROUTING -o gwan -m mark --mark 0x10 -j ${natval}
    ip6tables -t nat -A POSTROUTING -o wan -m mark --mark 0x10 -j ${nat6val}
    ip6tables -t nat -A POSTROUTING -o gwan -m mark --mark 0x10 -j ${nat6val}

    # Allow access to servers
    ${concatStrings (map (n: ''
      ip46tables -A FORWARD -i ${n} -o slan -j ACCEPT
    '') (filter (n: n != "slan") config.myNatIfs))}
  '';
}

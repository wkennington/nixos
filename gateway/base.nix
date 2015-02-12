{ config, lib, ... }:
with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  net = calculated.myNetMap;

  networkId = net.internalMachineMap.${config.networking.hostName};
in
{
  imports = [
    ./sub/base-dhcpd.nix
    ./sub/base-dnsmasq.nix
  ];
  networking = {
    interfaces = {
      wan.useDHCP = true;
    } // flip mapAttrs vars.internalVlanMap (_: vid: {
      ip4 = mkOverride 0 ([
        { address = "${net.priv4}${toString vid}.${toString networkId}"; prefixLength = 24; }
      ] ++ optional calculated.iAmOnlyGateway
        { address = "${net.priv4}${toString vid}.1"; prefixLength = 32; });
      ip6 = mkOverride 0 [
        { address = "${net.pub6}${toString vid}::${toString networkId}"; prefixLength = 64; }
        { address = "${net.priv6}${toString vid}::${toString networkId}"; prefixLength = 64; }
      ];
    });

    vlans = mkOverride 0 (
      flip mapAttrs vars.internalVlanMap
        (_: vid: { id = vid; interface = "lan"; }));

    firewall.extraCommands = mkOrder 2 ''
      # Forward Outbound Connections
      ${concatStrings (map (n: ''
        ip46tables -w -A FORWARD -i ${n} -o wan -j ACCEPT
        ip46tables -w -A FORWARD -i ${n} -o gwan -j ACCEPT
        ip6tables -w -A FORWARD -i ${n} -o hurricane -j ACCEPT
        ip46tables -A FORWARD -i ${n} -o tinc.vpn -j ACCEPT
      '') vars.gateway.natIfs)}

      # Masquerade all private connections
      iptables -t mangle -A PREROUTING -m set --match-set private src -j MARK --set-mark 0x10
      iptables -t nat -A POSTROUTING -m mark --mark 0x10 -j MASQUERADE

      # Allow access to servers
      ${concatStrings (map (n: ''
        ip46tables -A FORWARD -i ${n} -o slan -j ACCEPT
      '') (filter (n: n != "slan") vars.gateway.natIfs))}
    '';
  };
}

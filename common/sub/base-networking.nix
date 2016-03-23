{ config, lib, ... }:
with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  calculated = (import ./calculated.nix { inherit config lib; });

  net = calculated.myNetMap;
  networkId = net.internalMachineMap.${config.networking.hostName}.id;
  hasWanIf = config.networking.interfaces ? "wan";
in
{
  myNatIfs = calculated.myNetData.vlans;

  networking = mkMerge [
    {
      dhcpcd.extraConfig = ''
        noipv4ll
        nohook mtu  # Break Cable modem negotiation
      '';
    }
    (mkIf (!calculated.iAmRemote) {
      defaultGateway = mkDefault (if !hasWanIf then calculated.myGatewayIp4
        else if calculated.myPublicIp4 != null then net.pub4Gateway else null);

      interfaces = mkMerge [
        { lan = { }; }
        (listToAttrs (flip map (calculated.myNetData.vlans ++ [ "lan" ]) (vlan:
          let
            vid = vars.internalVlanMap.${vlan};
          in
          nameValuePair vlan {
            ip4 = mkOverride 0 ([
              { address = "${net.priv4}${toString vid}.${toString networkId}"; prefixLength = 24; }
            ] ++ optional calculated.iAmOnlyGateway
              { address = "${net.priv4}${toString vid}.1"; prefixLength = 32; });
            ip6 = mkOverride 0 [
              { address = "${net.pub6}${toString vid}::${toString networkId}"; prefixLength = 64; }
              { address = "${net.priv6}${toString vid}::${toString networkId}"; prefixLength = 64; }
            ];
          }
        )))
        (mkIf (calculated.myPublicIp4 != null) ({ wan.ip4 = [ {
          address = calculated.myPublicIp4;
          prefixLength = net.pub4PrefixLength;
        } ]; }))
      ];

      vlans = listToAttrs (flip map calculated.myNetData.vlans (vlan:
        nameValuePair vlan {
          id = vars.internalVlanMap.${vlan};
          interface = if config.networking.interfaces ? "10glan" && vlan == "slan" then "10glan" else "lan";
        }
      ));

      useDHCP = false;

      nameservers = if hasWanIf then [ "8.8.4.4" "8.8.8.8" ] else calculated.myDnsIp4;
    })
    (mkIf calculated.iAmRemote {
      useDHCP = true;
    })
  ];
}

{ config, lib, ... }:
with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  calculated = (import ./calculated.nix { inherit config lib; });

  hasWanIf = config.networking.interfaces ? "wan";
in
{
  networking = mkMerge [
    {
      dhcpcd.extraConfig = ''
        noipv4ll
      '';
    }
    (mkIf (!calculated.iAmRemote) {
      defaultGateway = mkDefault (if hasWanIf then null else calculated.myGatewayIp4);

      interfaces = {
        lan = { };
      } // listToAttrs (flip map calculated.myNetData.vlans (vlan:
        nameValuePair vlan {
          ip4 = mkDefault [ { address = calculated.myInternalIp4; prefixLength = 24; } ];
        }
      ));

      vlans = listToAttrs (flip map calculated.myNetData.vlans (vlan:
        nameValuePair vlan {
          id = vars.internalVlanMap.${vlan};
          interface = "lan";
        }
      ));

      useDHCP = false;

      nameservers = if hasWanIf then [ "8.8.4.4" "8.8.8.8" ] else calculated.myGatewaysIp4;
    })
  ];
}

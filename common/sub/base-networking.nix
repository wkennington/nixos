{ config, lib, ... }:
with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  calculated = (import ./calculated.nix { inherit config lib; });

  hasWanIf = config.networking.interfaces ? "wan";
in
{
  networking = mkIf (!calculated.iAmRemote) {
    defaultGateway = mkDefault (if hasWanIf then null else calculated.myGatewayIp4);

    interfaces = {
      lan = { };
      slan = mkDefault {
        ip4 = [ { address = calculated.myInternalIp4; prefixLength = 24; } ];
      };
    };

    vlans.slan = { id = vars.internalVlanMap.slan; interface = "lan"; };

    useDHCP = false;

    nameservers = if hasWanIf then [ "8.8.4.4" "8.8.8.8" ] else
      map (n: calculated.internalIp4 n "slan") calculated.myNetMap.gateways;
  };
}

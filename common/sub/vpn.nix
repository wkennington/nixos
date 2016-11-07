{ config, lib, ... }:

with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  calculated = (import ./calculated.nix { inherit config lib; });

  id = vars.vpn.idMap.${config.networking.hostName};

  remoteNets = if calculated.iAmRemote then vars.netMaps else
    flip filterAttrs vars.netMaps
      (n: { priv4, ... }: priv4 != calculated.myNetMap.priv4);
  extraRoutes = mapAttrsToList (n: { priv4, ... }: "${priv4}0.0/16") remoteNets;
in
{
  myNatIfs = [ "${vars.domain}.vpn" ];
  
  networking = {
    interfaces."${vars.domain}.vpn" = {
      ip4 = optionals (vars.vpn ? subnet4) [
        { address = "${vars.vpn.subnet4}${toString id}"; prefixLength = 24; }
      ];
      ip6 = optionals (vars.vpn ? subnet6) [
        { address = "${vars.vpn.subnet6}${toString id}"; prefixLength = 64; }
      ];
    };

    localCommands = flip concatMapStrings extraRoutes (n: ''
      ip route del "${n}" dev "${vars.domain}.vpn" >/dev/null 2>&1 || true
      ip route add "${n}" dev "${vars.domain}.vpn"
    '');
  };
}

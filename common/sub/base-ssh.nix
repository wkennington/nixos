{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatMap
    flip
    mapAttrs
    optionals;

  calculated = (import ./calculated.nix { inherit config lib; });
  vars = (import ../../customization/vars.nix { inherit lib; });
in
{
  programs.ssh = {
    knownHosts = flip mapAttrs vars.sshHostKeys (host: key: {
      hostNames = let
        dc = calculated.dc host;
        netMap = vars.netMaps."${dc}";
        netData = netMap.internalMachineMap."${host}";
      in [
        host
        "${host}.${vars.domain}"
      ] ++ optionals (calculated.isRemote host) [
        "${host}.remote.${vars.domain}"
        "${host}.remote"
      ] ++ optionals (!calculated.isRemote host) ([
        "${host}.${dc}.${vars.domain}"
        "${host}.${dc}"
      ] ++ flip concatMap netData.vlans (vlan: [
        "${host}.${vlan}.${vars.domain}"
        "${host}.${vlan}"
        "${host}.${vlan}.${dc}.${vars.domain}"
        "${host}.${vlan}.${dc}"
      ])) ++ optionals (vars.vpn.idMap ? "${host}") [
        "${host}.vpn.${vars.domain}"
        "${host}.vpn"
      ];
      publicKey = key;
    });
    package = pkgs.openssh;
  };
}

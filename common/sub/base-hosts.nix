{ config, lib, ... }:

with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  calculated = (import ./calculated.nix { inherit config lib; });

  ipHosts' = concatLists (flip mapAttrsToList vars.netMaps (dc: dcd:
    concatLists (flip mapAttrsToList dcd.internalMachineMap (host: data: [
        { "${calculated.internalIp4 host (head data.vlans)}" = "${host}.${vars.domain}"; }
        { "${calculated.internalIp4 host (head data.vlans)}" = "${host}.${dc}.${vars.domain}"; }
        { "${calculated.bmcIp4 host}" = "${host}-bmc.${vars.domain}"; }
        { "${calculated.bmcIp4 host}" = "${host}-bmc.${dc}.${vars.domain}"; }
      ] ++ flip concatMap data.vlans (vlan: [
        { "${calculated.internalIp4 host vlan}" = "${host}.${vlan}.${vars.domain}"; }
        { "${calculated.internalIp4 host vlan}" = "${host}.${vlan}.${dc}.${vars.domain}"; }
      ])
    ))
  ));

  ipHosts = foldAttrs (n: a: [ n ] ++ a) [ ] ipHosts';
in
{
  networking.extraHosts = concatStrings (flip mapAttrsToList ipHosts (ip: hosts: ''
    ${ip} ${concatStringsSep " " hosts}
  ''));
}

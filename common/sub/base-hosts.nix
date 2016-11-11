{ config, lib, ... }:

with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  calculated = (import ./calculated.nix { inherit config lib; });

  ipHosts' = concatLists (flip mapAttrsToList vars.netMaps (dc: dcd:
    concatLists (flip mapAttrsToList dcd.internalMachineMap (host: data: [
        # We actually don't want this because it conflicts with public names
        #{ "${calculated.internalIp4 host (head data.vlans)}" = "${host}.${vars.domain}"; }
        #{ "${calculated.internalIp4 host (head data.vlans)}" = "${host}.${dc}.${vars.domain}"; }
        { "${calculated.bmcIp4 host}" = "${host}-bmc.${vars.domain}"; }
        { "${calculated.bmcIp4 host}" = "${host}-bmc.${dc}.${vars.domain}"; }
      ] ++ flip concatMap data.vlans (vlan: [
        { "${calculated.internalIp4 host vlan}" = "${host}.${vlan}.${vars.domain}"; }
        { "${calculated.internalIp4 host vlan}" = "${host}.${vlan}.${dc}.${vars.domain}"; }
      ])
    ))
  )) ++ concatLists (flip mapAttrsToList vars.vpn.idMap (host: id:
    [
      { "${calculated.vpnIp6 host}" = "${host}.vpn.${vars.domain}"; }
      { "${calculated.vpnIp4 host}" = "${host}.vpn.${vars.domain}"; }
    ]
  )) ++ concatLists (flip map (filter (n: vars.vpn.idMap ? "${n}") vars.remotes) (host:
    [
      { "${calculated.vpnGwIp6 host}" = "${host}.remote.${vars.domain}"; }
      { "${calculated.vpnGwIp4 host}" = "${host}.remote.${vars.domain}"; }
    ]
  ));

  ipHosts = foldAttrs (n: a: [ n ] ++ a) [ ] ipHosts';
in
{
  networking.extraHosts = concatStrings (flip mapAttrsToList ipHosts (ip: hosts: ''
    ${ip} ${concatStringsSep " " hosts}
  ''));
}

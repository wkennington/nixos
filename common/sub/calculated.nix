{ config, lib, ... }:
with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  host = config.networking.hostName;
in
rec {
  dc = name: let
    dcs = flip filterAttrs vars.netMaps (dc: { internalMachineMap, ... }:
      any (n: n == config.networking.hostName) (attrNames internalMachineMap));
  in head (attrNames dcs);
  vpnIp4 = name: "${vars.vpn.subnet}${toString vars.vpn.idMap.${name}}";
  internalIp4Net = name: lan: let ndc = dc name; net = vars.netMaps.${ndc}; in
    "${net.priv4}${toString vars.internalVlanMap.${lan}}.0/24";
  internalIp4 = name: lan: let ndc = dc name; net = vars.netMaps.${ndc}; in
    "${net.priv4}${toString vars.internalVlanMap.${lan}}.${toString net.internalMachineMap.${name}}";
  domain = name: "${dc name}.${vars.domain}";

  myDc = dc host;
  myDomain = domain host;
  myVpnIp4 = vpnIp4 host;
  myInternalIp4 = internalIp4 host "slan";
  myInternalIp4Net = internalIp4Net host "slan";
  myNetMap = vars.netMaps.${myDc};
  iAmGateway = any (n: config.networking.hostName == n) myNetMap.gateways;
  iAmOnlyGateway = iAmGateway && length (myNetMap.gateways) == 1;

  myCeph = {
    mons = myNetMap.ceph.mons;
    monIps = map (s: internalIp4 s "slan") myNetMap.ceph.mons;
    fsId = myNetMap.ceph.fsId;
  };
  myConsul = {
    servers = myNetMap.consul.servers;
    serverIps = map (s: internalIp4 s "slan") myNetMap.consul.servers;
  };
  myZookeeper = {
    servers = myNetMap.zookeeper.servers;
    serverIps = map vpnIp4 (attrNames myNetMap.zookeeper.servers);
    url = "zk://${concatStringsSep "," serverIps}";
  };
}

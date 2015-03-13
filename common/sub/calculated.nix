{ config, lib, ... }:
with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  host = config.networking.hostName;
in
rec {
  isRemote = name: any (n: n == name) vars.remotes;
  dc = name: let
    dcs = flip filterAttrs vars.netMaps (dc: { internalMachineMap, ... }:
      any (n: n == name) (attrNames internalMachineMap));
  in if isRemote name then "remote" else head (attrNames dcs);
  vpnIp4 = name: "${vars.vpn.subnet}${toString vars.vpn.idMap.${name}}";
  internalIp4Net = name: lan: let ndc = dc name; net = vars.netMaps.${ndc}; in
    "${net.priv4}${toString vars.internalVlanMap.${lan}}.0/24";
  internalIp4 = name: lan: let ndc = dc name; net = vars.netMaps.${ndc}; in
    "${net.priv4}${toString vars.internalVlanMap.${lan}}.${toString net.internalMachineMap.${name}}";
  gatewayIp4 = name: lan: let ndc = dc name; net = vars.netMaps.${ndc}; in
    "${net.priv4}${toString vars.internalVlanMap.${lan}}.1";
  domain = name: "${dc name}.${vars.domain}";

  iAmRemote = isRemote host;
  myDc = dc host;
  myDomain = domain host;
  myVpnIp4 = vpnIp4 host;
  myInternalIp4 = internalIp4 host "slan";
  myGatewayIp4 = gatewayIp4 host "slan";
  myNasIp4s = flip map myNetMap.nasIds
    (n: "${myNetMap.priv4}${toString vars.internalVlanMap."dlan"}.${toString n}");
  myInternalIp4Net = internalIp4Net host "slan";
  myNetMap = vars.netMaps.${myDc};
  iAmGateway = any (n: host == n) myNetMap.gateways;
  iAmOnlyGateway = iAmGateway && length (myNetMap.gateways) == 1;
  myTimeZone = if iAmRemote then "UTC" else myNetMap.timeZone;

  myCeph = {
    mons = myNetMap.ceph.mons;
    monIps = map (s: internalIp4 s "slan") myNetMap.ceph.mons;
    fsId = myNetMap.ceph.fsId;
    osds = myNetMap.ceph.osds.${host};
  };
  myConsul = {
    servers = myNetMap.consul.servers;
    serverIps = map (s: internalIp4 s "slan") myNetMap.consul.servers;
  };
  myMongodb = {
    servers = myNetMap.mongodb.servers;
    serverIps = map vpnIp4 myNetMap.mongodb.servers;
  };
  myZookeeper = {
    servers = myNetMap.zookeeper.servers;
    serverIps = map vpnIp4 (attrNames myNetMap.zookeeper.servers);
    url = "zk://${concatStringsSep "," serverIps}";
  };
}

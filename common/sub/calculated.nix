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
      internalMachineMap ? "${name}");
  in if isRemote name then "remote" else head (attrNames dcs);
  vpnIp4 = name: "${vars.vpn.subnet}${toString vars.vpn.idMap.${name}}";
  internalIp4Net = name: lan: let ndc = dc name; net = vars.netMaps.${ndc}; in
    "${net.priv4}${toString vars.internalVlanMap.${lan}}.0/24";
  internalIp4 = name: lan: let ndc = dc name; net = vars.netMaps.${ndc}; in
    "${net.priv4}${toString vars.internalVlanMap.${lan}}.${toString net.internalMachineMap.${name}.id}";
  bmcIp4 = name: let ndc = dc name; net = vars.netMaps.${ndc}; in
    "${net.priv4}${toString vars.internalVlanMap."mlan"}.1${toString net.internalMachineMap.${name}.id}";
  publicIp4 = name: let ndc = dc name; net = vars.netMaps.${ndc}; in
    if !(net ? "pub4MachineMap" && net.pub4MachineMap ? "${name}") then null
      else "${net.pub4}${toString net.pub4MachineMap.${name}}";
  publicIp6 = name: let ndc = dc name; net = vars.netMaps.${ndc}; in
    if !(net ? "pub6MachineMap" && net.pub6MachineMap ? "${name}") then null
      else "${net.pub6}${toString net.pub6MachineMap.${name}}";
  gatewayIp4 = name: lan: let ndc = dc name; net = vars.netMaps.${ndc}; in
    "${net.priv4}${toString vars.internalVlanMap.${lan}}.1";
  gatewayIp6 = name: lan: let ndc = dc name; net = vars.netMaps.${ndc}; in
    "${net.priv6}${toString vars.internalVlanMap.${lan}}::1";
  domain = name: "${dc name}.${vars.domain}";
  dnsIp4 = lan: map (flip internalIp4 lan) myNetMap.dnsServers;
  ntpIp4 = lan: flip map myNetMap.ntpServers ({ server, weight }: {
    server = internalIp4 server lan;
    inherit weight;
  });

  iAmRemote = isRemote host;
  myDc = dc host;
  myDomain = domain host;
  myVpnIp4 = vpnIp4 host;
  myInternalIp4 = internalIp4 host (head myNetData.vlans);
  myPublicIp4 = publicIp4 host;
  myPublicIp6 = publicIp6 host;
  myGatewaysIp4 = map (gatewayIp4 host) myNetData.vlans;
  myGatewayIp4 = head myGatewaysIp4;
  myNasIp4s = flip map myNetMap.nasIds
    (n: "${myNetMap.priv4}${toString vars.internalVlanMap."dlan"}.${toString n}");
  myInternalIp4Net = internalIp4Net host (head myNetData.vlans);
  myNetMap = vars.netMaps.${myDc};
  myNetData = myNetMap.internalMachineMap.${host};
  iAmGateway = any (n: host == n) myNetMap.gateways;
  iAmOnlyGateway = iAmGateway && length (myNetMap.gateways) == 1;
  myTimeZone = if iAmRemote then "UTC" else myNetMap.timeZone;

  myDnsServers =
    if iAmRemote then
      vars.pubDnsServers
    else if any (n: host == n) myNetMap.dnsServers then
      myNetMap.pubDnsServers
    else
      dnsIp4 (head myNetData.vlans);

  myNtpServers =
    if iAmRemote then
      vars.pubNtpServers
    else if any (n: host == n.server) myNetMap.ntpServers then
      myNetMap.pubNtpServers
    else
      ntpIp4 (head myNetData.vlans);

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

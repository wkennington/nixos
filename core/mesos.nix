{ config, lib, ... }:
with lib;
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  isMaster = flip any (attrNames calculated.myZookeeper.servers)
    (name: config.networking.hostName == name);
  myIp = calculated.myVpnIp4;
  servers = map (n: "${n}:2181") calculated.myZookeeper.serverIps;
  zkUrl = "zk://${concatStringsSep "," servers}/mesos";
in
{
  imports = [ ./zookeeper.nix ];

  networking.firewall = {
    extraCommands = mkMerge [
      (mkOrder 0 ''
        # Cleanup if we haven't already
        iptables -D INPUT -p tcp --dport 5050 -j mesos || true
        iptables -D INPUT -p tcp --dport 5051 -j mesos || true
        iptables -F mesos || true
        iptables -X mesos || true
        ipset destroy mesos || true
      '')
      (''
        # Allow remote mesos to communicate
        ipset create mesos hash:ip family inet
        ${flip concatMapStrings calculated.myZookeeper.serverIps (n: ''
          ipset add mesos "${n}"
        '')}
        iptables -N mesos
        iptables -A mesos -m set --match-set mesos src -j ACCEPT
        iptables -A mesos -j RETURN
        iptables -A INPUT -p tcp --dport 5050 -j mesos
        iptables -A INPUT -p tcp --dport 5051 -j mesos
      '')
    ];
    extraStopCommands = ''
      iptables -D INPUT -p tcp --dport 5050 -j mesos || true
      iptables -D INPUT -p tcp --dport 5051 -j mesos || true
      iptables -F mesos || true
      iptables -X mesos || true
      ipset destroy mesos || true
    '';
  };

  services.mesos = {
    slave = {
      enable = true;
      master = zkUrl;
      extraCmdLineOptions = [ "--ip=${myIp}" ];
    };
    master = mkIf isMaster {
      enable = true;
      # We must have a majority of servers in the quorum
      quorum = (length calculated.myZookeeper.serverIps + 2) / 2;
      zk = zkUrl;
      extraCmdLineOptions = [ "--ip=${myIp}" ];
    };
  };
  virtualisation.docker.enable = true;
}

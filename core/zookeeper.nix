{ config, lib, ... }:
with lib;
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  servers = zipLists calculated.myZookeeper.serverIps
    (attrValues calculated.myZookeeper.servers);
  myId = calculated.myZookeeper.servers.${config.networking.hostName};
in
{
  networking.firewall = {
    extraCommands = mkMerge [
      (mkOrder 0 ''
        # Cleanup if we haven't already
        iptables -D INPUT -p tcp --dport 2181 -j zookeeper || true
        iptables -D INPUT -p tcp --dport 2888 -j zookeeper || true
        iptables -D INPUT -p tcp --dport 3888 -j zookeeper || true
        iptables -F zookeeper || true
        iptables -X zookeeper || true
        ipset destroy zookeeper || true
      '')
      (''
        # Allow remote zookeepers to communicate
        ipset create zookeeper hash:ip family inet
        ${flip concatMapStrings calculated.myZookeeper.serverIps (n: ''
          ipset add zookeeper "${n}"
        '')}
        iptables -N zookeeper
        iptables -A zookeeper -m set --match-set zookeeper src -j ACCEPT
        iptables -A zookeeper -j RETURN
        iptables -A INPUT -p tcp --dport 2181 -j zookeeper
        iptables -A INPUT -p tcp --dport 2888 -j zookeeper
        iptables -A INPUT -p tcp --dport 3888 -j zookeeper

        # Allow zookeeper to connect to itself and other nodes
        ip46tables -A OUTPUT -p tcp --dport 2888 -m owner --uid-owner zookeeper -j ACCEPT
        ip46tables -A OUTPUT -p tcp --dport 3888 -m owner --uid-owner zookeeper -j ACCEPT
      '')
    ];
    extraStopCommands = ''
      iptables -D INPUT -p tcp --dport 2181 -j zookeeper || true
      iptables -D INPUT -p tcp --dport 2888 -j zookeeper || true
      iptables -D INPUT -p tcp --dport 3888 -j zookeeper || true
      iptables -F zookeeper || true
      iptables -X zookeeper || true
      ipset destroy zookeeper || true
    '';
  };
  services.zookeeper = {
    enable = true;
    id = myId;
    servers = flip concatMapStrings servers ({ fst, snd }: ''
      server.${toString snd}=${fst}:2888:3888
    '');
  };
}

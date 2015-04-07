{ config, lib, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
in
with lib;
{
  networking.firewall = {
    extraCommands = mkMerge [
      (mkOrder 0 ''
        # Cleanup if we haven't already
        iptables -D INPUT -p tcp --dport 27017 -j mongodb || true
        iptables -F mongodb || true
        iptables -X mongodb || true
        ipset destroy mongodb || true
      '')
      (''
        # Allow remote mongodb replicas to communicate
        ipset create mongodb hash:ip family inet
        ${flip concatMapStrings calculated.myMongodb.serverIps (n: ''
          ipset add mongodb "${n}"
        '')}
        iptables -N mongodb
        iptables -A mongodb -m set --match-set mongodb src -j ACCEPT
        iptables -A mongodb -j RETURN
        iptables -A INPUT -p tcp --dport 27017 -j mongodb

        # Allow mongodb to connect to itself and other nodes
        ip46tables -A OUTPUT -p tcp --dport 27017 -m owner --uid-owner mongodb -j ACCEPT
      '')
    ];
    extraStopCommands = ''
      iptables -D INPUT -p tcp --dport 27017 -j mongodb || true
      iptables -F mongodb || true
      iptables -X mongodb || true
      ipset destroy mongodb || true
    '';
  };
  services.mongodb = {
    enable = true;
    bind_ip = "0.0.0.0";
    replSetName = calculated.myDomain;
    extraConfig = ''
      keyFile = /conf/mongodb/keyfile
    '';
  };
}

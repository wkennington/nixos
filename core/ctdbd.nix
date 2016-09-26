{ config, lib, pkgs, ... }:

with lib;
let
  needed = [
    "functions"
    "events.d/00.ctdb"
    "events.d/01.reclock"
    "events.d/10.interface"
    "events.d/11.routing"
    "events.d/99.timeout"
  ];
  files = {
    "ctdb/ctdbd.conf".text = ''
      CTDBD=${samba}/bin/ctdbd
      CTDB_PIDFILE=/run/ctdb/ctdb.pid
      CTDB_BASE=/etc/ctdb
      CTDB_DBDIR=/var/lib/ctdb
      CTDB_DBDIR_PERSISTENT=/var/lib/ctdb/persistent
      CTDB_DBDIR_STATE=/var/lib/ctdb/state
      CTDB_DEBUGLEVEL=5
      CTDB_EVENT_SCRIPT_DIR=/etc/ctdb/events.d
      CTDB_LOGGING=syslog
      CTDB_NODES=/etc/ctdb/nodes
      CTDB_PUBLIC_ADDRESSES=/etc/ctdb/public_addresses
      CTDB_RECOVERY_LOCK=/ceph/ctdb/reclock
      CTDB_SOCKET=/run/ctdb/ctdbd.socket
      CTDB_STARTUP_TIMEOUT=60

      CTDB_VARDIR=/var/lib/ctdb

      CTDB_NOSETSCHED=yes
    '';
    "ctdb/public_addresses".text = ''
    '';
    "ctdb/nodes".text = ''
    '';
  } // listToAttrs (flip map needed
    (n: nameValuePair "ctdb/${n}" { source = "${samba}/etc/ctdb/${n}"; }));

  samba = config.services.samba.package;

  ctdbPath = pkgs.buildEnv {
    name = "ctdb-path";
    paths = [
      samba
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.gnused
      pkgs.ethtool
      pkgs.iproute
      pkgs.iptables
      pkgs.net-tools
      pkgs.procps
      pkgs.tdb
      pkgs.util-linux_full
      pkgs.which
    ];
    pathsToLink = [
      "/bin"
    ];
    ignoreCollisions = true;
  };
in
{
  networking.firewall = {
    extraCommands = mkMerge [
      (mkOrder 0 ''
        # Cleanup if we haven't already
        iptables -D INPUT -p tcp --dport 4379 -j ctdb || true
        iptables -F ctdb || true
        iptables -X ctdb || true
        ipset destroy ctdb || true
      '')
      (''
        # Allow remote ctdb instances to sync up
        ipset create ctdb hash:ip family inet
        iptables -N ctdb
        iptables -A ctdb -m set --match-set ctdb src -j ACCEPT
        iptables -A ctdb -j RETURN
        iptables -A INPUT -p tcp --dport 4379 -j ctdb

        # Allow ctdb to connect to itself and other nodes
        ip46tables -A OUTPUT -p tcp --dport 4379 -m owner --uid-owner root -j ACCEPT
      '')
    ];
    extraStopCommands = ''
      iptables -D INPUT -p tcp --dport 4379 -j ctdb || true
      iptables -F ctdb || true
      iptables -X ctdb || true
      ipset destroy ctdb || true
    '';
  };

  environment.etc = files;

  systemd.services.ctdbd = {
    description = "CTDB Daemon";
    wantedBy = [ "multi-user.target" ];
    requires = [ "ceph.mount" "network.target" ];
    after = [ "ceph.mount" "network.target" ];

    path = [ ctdbPath ];

    environment.CTDBD_CONF = "/etc/ctdb/ctdbd.conf";

    restartTriggers = flip mapAttrsToList files
      (name: data: config.environment.etc.${name}.source);

    preStop = ''
      ${samba}/bin/ctdb stop
      ${samba}/bin/ctdb shutdown
    '';

    serviceConfig = {
      Type = "forking";
      ExecStart = "@${samba}/bin/ctdbd_wrapper ctdbd /run/ctdb/ctdbd.pid start";
      PIDFile = "/run/ctdb/ctdbd.pid";
    };
  };
}

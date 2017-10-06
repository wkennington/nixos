{ config, lib, pkgs, ... }:
let
  numCephUsers = 48;
  calculated = (import ./sub/calculated.nix { inherit config lib; });
in
with lib;
{
  require = [ ./sub/ceph-module.nix ];
  environment.systemPackages = [ config.cephPackage ];
  environment.etc."ceph/ceph.conf".text = ''
    [global]
      fsid = ${calculated.myCeph.fsId};
      mon initial members = ${concatStringsSep ", " calculated.myNetMap.ceph.mons}
      mon host = ${concatStringsSep ", " calculated.myCeph.monIps}
      log file = /dev/null
      log to stderr = false
      err to stderr = false
      log to syslog = true
      err to syslog = true
      mon cluster log to syslog = true
      mon cluster log file = /dev/null
      mgr module path = ${config.cephPackage.lib}/lib/ceph/mgr
      public network = ${calculated.myInternalIp4Net}
      auth cluster required = cephx
      auth service required = cephx
      auth client required = cephx
  '';
  fileSystems = [
    {
      mountPoint = "/etc/ceph";
      fsType = "none";
      device = "/conf/ceph";
      neededForBoot = true;
      options = [
        "defaults"
        "bind"
      ];
    }
  ];
  networking.firewall.extraCommands = ''
    # Allow inbound connections to ceph daemons
    # TODO(wak): Only enable when osd or mds is enabled
    iptables -A INPUT -p tcp --dport 6800:6900 -s ${calculated.myInternalIp4Net} -j ACCEPT

    # Allow connections to ceph mons
    iptables -A OUTPUT -d ${calculated.myInternalIp4Net} -p tcp --dport 6789 -j ACCEPT

    # Allow connections to other ceph services
    iptables -A OUTPUT -d ${calculated.myInternalIp4Net} -p tcp --dport 6800:6900 -j ACCEPT
  '';
  users = {
    extraUsers = {
      ceph-mon = {
        uid = 100000;
        group = "ceph";
      };
      ceph-mds = {
        uid = 100001;
        group = "ceph";
      };
      ceph-mgr = {
        uid = 100002;
        group = "ceph";
      };
    } // listToAttrs (flip map (range 0 (numCephUsers - 1)) (n:
      nameValuePair "ceph-osd${toString n}" { uid = 100100 + n; group = "ceph"; useDefaultShell = true; }));
    extraGroups.ceph.gid = 100000;
  };
}

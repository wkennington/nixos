{ config, lib, pkgs, ... }:
let
  numCephUsers = 48;
  calculated = (import ./sub/calculated.nix { inherit config lib; });
in
with lib;
{
  environment.systemPackages = [ pkgs.ceph ];
  environment.etc."ceph/ceph.conf".text = ''
    [global]
      fsid = ${calculated.myCeph.fsId};
      mon initial members = ${concatStringsSep ", " calculated.myNetMap.ceph.mons}
      mon host = ${concatStringsSep ", " calculated.myCeph.monIps}
    [osd]
      filestore zfs_snap = 1
      journal_aio = 0
      journal_dio = 0
    [mds]
      keyring = /etc/ceph/ceph.mds.keyring
  '';
  fileSystems = [
    {
      mountPoint = "/etc/ceph";
      fsType = "none";
      device = "/conf/ceph";
      neededForBoot = true;
      options = "defaults,bind";
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
  systemd.automounts = [ {
    wantedBy = [ "remote-fs.target" ];
    where = "/ceph";
  } ];
  systemd.mounts = [ {
    wants = [ "ip-up.target" ];
    wantedBy = [ "remote-fs.target" ];
    after = [ "network.target" "network-interfaces.target" "ip-up.target" "ceph-mds.service" "ceph-mon.service" ];
    type = "ceph";
    what = "${concatStringsSep "," calculated.myCeph.monIps}:/";
    where = "/ceph";
    options = "name=admin,secretfile=/etc/ceph/ceph.client.admin.key";
    #options = "name=admin,secretfile=/etc/ceph/ceph.client.admin.key,fsc,dcache";
  } ];
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
    } // listToAttrs (flip map (range 0 (numCephUsers - 1)) (n:
      nameValuePair "ceph-osd${toString n}" { uid = 100100 + n; group = "ceph"; }));
    extraGroups.ceph.gid = 100000;
  };
}

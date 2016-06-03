{ config, pkgs, lib, ... }:
with lib;
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  stateDir = "/var/lib/ceph/mon/ceph-${config.networking.hostName}";
  monCfg = pkgs.writeText "ceph-mon.conf" ''
    [global]
      fsid = ${calculated.myCeph.fsId}
      mon initial members = ${concatStringsSep ", " calculated.myNetMap.ceph.mons}
      mon host = ${concatStringsSep ", " calculated.myCeph.monIps}
      mon data = ${stateDir}
      admin socket = /run/ceph/ceph-mon.${config.networking.hostName}.asok
      log file = /dev/null
      log to stderr = false
      err to stderr = false
      log to syslog = true
      err to syslog = true
      mon cluster log to syslog = true
      mon cluster log file = /dev/null
      public network = ${calculated.myInternalIp4Net}
      auth cluster required = cephx
      auth service required = cephx
      auth client required = cephx
      osd journal size = 1024
      filestore xattr use omap = true
      osd pool default size = 2
      osd pool default min size = 1
      osd pool default pg num = 333
      osd pool default pgp num = 333
      osd crush chooseleaf type = 1
  '';
in
{
  imports = [
    ../common/ceph.nix
  ];
  networking.firewall.extraCommands = ''
    iptables -A INPUT -p tcp --dport 6789 -s ${calculated.myInternalIp4Net} -j ACCEPT
  '';

  systemd.services.ceph-mon = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "time-syncd.target" ];
    requires = [ "time-syncd.target" ];

    # Updating crush maps requires crushtool in the path
    path = [ config.cephPackage ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "@${config.cephPackage}/bin/ceph-mon ceph-mon -i ${config.networking.hostName} -c ${monCfg} -f";
      User = "ceph-mon";
      Group = "ceph";
      PermissionsStartOnly = true;
      Restart = "always";
    };

    preStart = ''
      mkdir -p -m 0775 /var/lib/ceph/mon
      if [ ! -d "${stateDir}" ]; then
        ceph-mon -i ${config.networking.hostName} --mkfs --keyring /etc/ceph/ceph.client.admin.keyring
      fi
      chmod 0700 ${stateDir}
      chown -R ceph-mon ${stateDir}
      
      mkdir -p -m 0775 /var/run/ceph
      chown ceph-mon:ceph /var/run/ceph
    '';
  };
}

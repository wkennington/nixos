{ config, pkgs, lib, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  stateDir = "/var/lib/ceph/mds/ceph-${config.networking.hostName}";
in
{
  networking.firewall.extraCommands = ''
    iptables -A INPUT -p tcp --dport 6800:6900 -s ${calculated.myInternalIp4Net} -j ACCEPT
    ip46tables -A OUTPUT -o lo -p tcp --dport 6800:6900 -j ACCEPT
  '';
  systemd.services.ceph-mds = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    restartTriggers = [ config.environment.etc."ceph/ceph.conf".source ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "@${pkgs.ceph}/bin/ceph-mds ceph-mds -i ${config.networking.hostName} -f --hot-standby 0";
      User = "ceph-mds";
      Group = "ceph";
      PermissionsStartOnly = true;
      Restart = "always";
    };
    preStart = ''
      mkdir -p ${stateDir}
      chmod 0700 ${stateDir}
      chown -R ceph-mds:ceph ${stateDir}
      mkdir -p -m 0775 /var/run/ceph
      chown ceph-mon:ceph /var/run/ceph
      mkdir -p -m 0775 /var/log/ceph
      chown ceph-mon:ceph /var/log/ceph
    '';
  };
}

{ config, pkgs, lib, utils, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  stateDir = n: "/var/lib/ceph/osd/ceph-${toString n}";
in
with lib;
{
  imports = [
    ../common/ceph.nix
  ];

  systemd.services = listToAttrs (flip map calculated.myCeph.osds (n:
    nameValuePair "ceph-osd${toString n}" {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "${utils.escapeSystemdPath (stateDir n)}.mount" ];

      restartTriggers = [ config.environment.etc."ceph/ceph.conf".source ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "@${pkgs.ceph}/bin/ceph-osd ceph-osd -i ${toString n} -d";
        User = "ceph-osd${toString n}";
        Group = "ceph";
        PermissionsStartOnly = true;
        Restart = "always";
      };

      preStart = ''
        chmod 0700 ${stateDir n}
        mkdir -p -m 0775 /var/run/ceph
        chown ceph-mon:ceph /var/run/ceph
        mkdir -p -m 0770 /var/log/ceph
        chown ceph-mon:ceph /var/log/ceph
      '';
    }));
}

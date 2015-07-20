{ config, pkgs, lib, utils, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  stateDir = n: "/var/lib/ceph/osd/ceph-${toString n}";

  osdScript = pkgs.writeScript "osd-script" ''
    #! ${pkgs.stdenv.shell} -e
    export PATH="${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.coreutils}/bin:${pkgs.utillinux}/bin"
    mkdir -p /var/lib/ceph
    exec 3>/var/lib/ceph/osds.lock
    flock 3 || exit 1
    env -0 | grep -zv '^PATH' | sed -z "s,.*,export '\0'; ," | tr '\0' ' ' >>/var/lib/ceph/osds
    echo -en "\0" >>/var/lib/ceph/osds
  '';

in
with lib;
{
  imports = [
    ../common/ceph.nix
  ];

  boot.supportedFilesystems = [ "btrfs" "zfs" ];

  services.udev.packages = [ (pkgs.writeTextFile {
    name = "osd-udev-rules";
    destination = "/etc/udev/rules.d/91-osd.rules";
    text = ''
      ENV{ID_PART_ENTRY_TYPE}=="6a8d2ac7-1dd2-11b2-99a6-080020736631", RUN+="${osdScript}"
    '';
  })];

  systemd.services."ceph-osd-loader" = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "local-fs.target" ];
    unitConfig.RequiresMountsFor = "/var/lib/ceph/osd/by-user";
    path = with pkgs; [ coreutils gawk gnused gnugrep e2fsprogs utillinux systemd btrfsProgs zfs inotifyTools ];
    script = ''
      lock () {
        exec 3>/var/lib/ceph/osds.lock
        flock 3
      }
      unlock () {
        EXTRA_EVENTS=$((EXTRA_EVENTS + 1))
        exec 3>&-
      }
      process_event () {
        if [ "$ACTION" = "remove" ]; then
          if [ "$ID_FS_TYPE" = "zfs_member" ]; then
            DIR="$(cat /proc/mounts | grep "^$ID_FS_LABEL" | awk '{print $2}')"
          elif [ "$ID_FS_TYPE" = "btrfs" ]; then
            DIR="$(cat /proc/mounts | grep "^$DEVNAME" | awk '{print $2}')"
          fi
          [ -z "$DIR" ] && return 0
          NUM="$(echo "$DIR" | sed 's,.*ceph-osd\(.*\),\1,g')"
          systemctl stop -s 9 "ceph-osd@$NUM" || true
          umount -f "$DIR" || true
          return 0
        fi

        # Find a free user / mountpoint
        ALL="$(seq 0 47 | awk '{print "ceph-osd"$0}')"
        ALLOC="$(cat /proc/mounts | awk '{print $2}' | grep '^/var/lib/ceph/osd/by-user' | xargs basename -a 2>/dev/null)" || true
        UNUSED="$(echo -e "$ALL\n$ALLOC" | sed '/^$/d' | sort -V | uniq -u)"

        SELECTED="$(echo "$UNUSED" | head -n 1)"
        DIR="/var/lib/ceph/osd/by-user/$SELECTED"
        NUM="$(echo "$SELECTED" | sed 's,ceph-osd\(.*\),\1,')"

        systemctl stop "ceph-osd@$NUM" || true

        # Mount the partition
        mkdir -p "$DIR"
        if [ "$ID_FS_TYPE" = "zfs_member" ]; then
          umount "$DIR" || true
          zpool export "$ID_FS_LABEL" || true
          zpool import -f "$ID_FS_UUID" || return 0
          mount -t zfs "$ID_FS_LABEL" "$DIR" || return 0
        elif [ "$ID_FS_TYPE" = "btrfs" ]; then
          umount "$DIR" || true
          mount -t btrfs -o defaults,noatime,user_subvol_rm_allowed,compress=lzo,space_cache "UUID=$ID_FS_UUID" "$DIR" || return 0
        else
          echo "Failed to determine the partition type on $DEVNAME" >&2
          return 0
        fi

        # Correctly own the osd
        chown "$SELECTED:ceph" "$DIR"
        chmod 0700 "$DIR"

        # Start the daemon
        systemctl start --no-block "ceph-osd@$NUM"
      }

      EXTRA_EVENTS=0
      touch /var/lib/ceph/osds.lock
      inotifywait -m /var/lib/ceph/osds.lock -e CLOSE_WRITE 2>&1 | while read e; do
        if [ "$EXTRA_EVENTS" -gt "0" ]; then
          EXTRA_EVENTS=$(($EXTRA_EVENTS - 1))
          continue
        fi
        lock
        if [ -f /var/lib/ceph/osds ]; then
          cat /var/lib/ceph/osds | while read -d ''$'\0' E; do
            (eval "$E"; process_event)
          done
          truncate -s 0 /var/lib/ceph/osds
        fi
        unlock
      done
    '';
  };

  systemd.services."ceph-osd@" = {
    after = [ "network.target" ];

    restartTriggers = [ config.environment.etc."ceph/ceph.conf".source ];

    path = [ config.cephPackage ];

    serviceConfig = {
      Type = "simple";
      User = "ceph-osd%i";
      Group = "ceph";
      PermissionsStartOnly = true;
      Restart = "always";
      UMask = "000";
    };

    preStart = ''
      mkdir -p -m 0775 /var/run/ceph
      chown ceph-mon:ceph /var/run/ceph
      mkdir -p -m 0770 /var/log/ceph
      chown ceph-mon:ceph /var/log/ceph
      mkdir -p /var/lib/ceph/osd
      chown ceph-mon:ceph /var/lib/ceph/osd
      chmod 0770 /var/lib/ceph/osd
    '';

    script = ''
      ID="$(cat "/var/lib/ceph/osd/by-user/$USER/whoami")"
      #rm -f "/var/lib/ceph/osd/ceph-osd$ID"
      #ln -s "/var/lib/ceph/osd/by-user/$USER" "/var/lib/ceph/osd/ceph-osd$ID"
      exec ceph-osd -i "$ID" --osd-data="/var/lib/ceph/osd/by-user/$USER" --osd-journal="/var/lib/ceph/osd/by-user/$USER/journal" -d
    '';

    postStart = ''
      ceph osd crush set "osd.$(cat "/var/lib/ceph/osd/by-user/$USER/whoami")" 1.0 host="${config.networking.hostName}"
    '';
  };
}

{ config, lib, pkgs, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  stateDir = "/var/lib/ceph/mgr/ceph-${config.networking.hostName}";

  pythonPackages = pkgs.python2Packages;

  cephMgr = pkgs.stdenv.mkDerivation {
    name = "ceph-mgr-wrapped";

    nativeBuildInputs = [
      pkgs.makeWrapper
      pythonPackages.python
    ];

    pythonPath = with pythonPackages; [
      cherrypy
      config.cephPackage.lib
      jinja2
    ];

    unpackPhase = "true";

    installPhase = ''
      declare -A pythonPathsSeen
      makePythonPath() {
        if [ -n "''${pythonPathsSeen[$1]}" ]; then return; fi
        pythonPathsSeen[$1]=1
        local ppath="$(toPythonPath "$1")"
        if [ -e "$ppath" ]; then
          addToSearchPath PYTHONPATH "$ppath"
        fi
        local prop="$1/nix-support/propagated-native-build-inputs"
        if [ -e "$prop" ]; then
          local new_path
          for new_path in $(cat "$prop"); do
            makePythonPath $new_path
          done
        fi
      }
      for lib in $pythonPath; do
        makePythonPath "$lib"
      done

      mkdir -p "$out"/bin
      ln -sv "${config.cephPackage}"/bin/ceph-mgr "$out"/bin
      wrapProgram "$out"/bin/ceph-mgr --prefix PYTHONPATH : "$PYTHONPATH"
    '';
  };
in
{
  imports = [
    ../common/ceph.nix
  ];

  systemd.services.ceph-mgr = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    restartTriggers = [ config.environment.etc."ceph/ceph.conf".source ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "@${cephMgr}/bin/ceph-mgr ceph-mgr -i ${config.networking.hostName} -f";
      ExecStopPost = "${config.cephPackage}/bin/ceph mgr fail ${config.networking.hostName}";
      User = "ceph-mgr";
      Group = "ceph";
      PermissionsStartOnly = true;
      Restart = "always";
    };

    preStart = ''
      mkdir -p ${stateDir}
      chmod 0700 ${stateDir}
      chown -R ceph-mgr:ceph ${stateDir}
      mkdir -p -m 0775 /var/run/ceph
      chown ceph-mon:ceph /var/run/ceph
    '';
  };
}

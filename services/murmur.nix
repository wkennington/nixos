{ config, lib, pkgs, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  vars = (import ../customization/vars.nix { inherit lib; });

  varDir = "/var/lib/murmur";

  murmur = pkgs.murmur_git;

  murmurUser = "murmur";
  murmurUid = 200000;

  sslCert = "/conf/ssl/mumble.${calculated.myDomain}.crt";
  sslKey = "/conf/ssl/mumble.${calculated.myDomain}.key";

  configFile = pkgs.writeText "murmur.ini" ''
    database=${varDir}/murmur.sqlite
    icesecretread=
    icesecretwrite=
    logfile=/var/log/murmur.log
    pidfile=/run/murmur.pid
    welcometext="<br />Welcome to <b>mumble.${vars.domain}</b>"
    port=64738
    host=0.0.0.0
    serverpassword=
    bandwidth=192000
    users=100
    textmessagelength=5000000
    imagemessagelength=100000000
    allowhtml=true
    registerName=William's Chat
    sslCert=${sslCert}
    sslKey=${sslKey}
    uname=${murmurUser}
    certrequired=True

    [Ice]
    Ice.Warn.UnkownProperties=1
    Ice.MessageSizeMax=65536
  '';
in
{
  environment.systemPackages = [ murmur ];

  networking.firewall = {
    allowedTCPPorts = [ 64738 ];
    allowedUDPPorts = [ 64738 ];
  };

  systemd.services.murmur = {
    description = "Murmur daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ murmur ];
    preStart = ''
      mkdir -p ${varDir}
      chown murmur ${varDir}
      chmod 0700 ${varDir}
    '';
    serviceConfig = {
      Type = "simple";
      ExecStart = "${murmur}/bin/murmurd -ini ${configFile} -fg";
    };
  };

  users.extraUsers = lib.singleton {
    name = murmurUser;
    uid = murmurUid;
    description = "Murmur daemon user";
    home = varDir;
    isSystemUser = true;
  };
}

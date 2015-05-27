{ config, pkgs, ... }:
let
  varDir = "/var/lib/murmur";

  murmurUser = "murmur";
  murmurUid = 200000;

  sslCert = "/conf/ssl/mumble.${vars.domain}.crt";
  sslKey = "/conf/ssl/mumble.${vars.domain}.key";

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
  environment.systemPackages = [ pkgs.murmur ];

  networking.firewall = {
    allowedTCPPorts = [ 64738 ];
    allowedUDPPorts = [ 64738 ];
  };

  systemd.services.murmur = {
    description = "Murmur daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.murmur ];
    preStart = ''
      mkdir -p ${varDir}
      chown murmur ${varDir}
      chmod 0700 ${varDir}
    '';
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.murmur}/bin/murmurd -ini ${configFile} -fg";
    };
  };

  users.extraUsers = pkgs.lib.singleton {
    name = murmurUser;
    uid = murmurUid;
    description = "Murmur daemon user";
    home = varDir;
    isSystemUser = true;
  };
}

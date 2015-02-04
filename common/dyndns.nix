{ config, pkgs, ... }:
{
  systemd.services.ddclient = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    preStart = ''
      mkdir -p /var/cache/ddclient
      cp /conf/ddclient.conf /tmp/ddclient.conf
      chown ddclient /var/cache/ddclient /tmp/ddclient.conf
    '';
    environment.SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt";
    serviceConfig = {
      Type = "simple";
      ExecStart = "@${pkgs.ddclient}/bin/ddclient ddclient -quiet -file /tmp/ddclient.conf";
      PermissionsStartOnly="true";
      User = "ddclient";
      Group = "nogroup";
    };
  };
  users.extraUsers.ddclient = {
    uid = config.ids.uids.ddclient;
    description = "ddclient daemon user";
  };
}

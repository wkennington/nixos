{ config, lib, pkgs, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  
  varDir = "/var/lib/sydent";
in
{
  networking.firewall.extraCommands = ''
    iptables -I INPUT -p tcp --dport 8090 -s "${calculated.myInternalIp4Net}" -j ACCEPT
  '';

  systemd.services.sydent = {
    description = "Sydent daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    preStart = ''
      mkdir -p "${varDir}"
      chown sydent "${varDir}"
      chmod 0700 "${varDir}"
    '';
    serviceConfig = {
      Type = "simple";
      PermissionsStartOnly = true;
      User = "sydent";
      WorkingDirectory = varDir;
      ExecStart = "${pkgs.sydent}/bin/sydent";
    };
  };

  users.extraUsers = lib.singleton {
    name = "sydent";
    uid = config.ids.uids.sydent;
    description = "Sydent daemon user";
    home = varDir;
    isSystemUser = true;
  };
}

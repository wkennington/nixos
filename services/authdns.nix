{ config, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.knot
  ];
  
  # Forward all of the incoming traffic to the correct port.
  networking.firewall.extraCommands = ''
    ip46tables -I INPUT -p udp --dport 1153 -j ACCEPT
    ip46tables -I INPUT -p tcp --dport 1153 -j ACCEPT
    ip46tables -t nat -A PREROUTING -i wan -p udp --dport 53 -j REDIRECT --to-port 1153
    ip46tables -t nat -A PREROUTING -i wan -p tcp --dport 53 -j REDIRECT --to-port 1153
  '';

  systemd.services.knot = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    description = "knot authoritative dns";
    preStart = ''
      rm -f /etc/knot
      ln -sv /ceph/knot/conf /etc/knot

      mkdir -p /run/knot
      chown knot:root /run/knot
      chmod 0755 /run/knot

      mkdir -p /var/lib/knot
      chown knot:root /var/lib/knot
      chmod 0700 /var/lib/knot
      rm -f /var/lib/knot/zones
      ln -sv /ceph/knot/zones /var/lib/knot/zones
    '';

    serviceConfig = {
      ExecStart = "${pkgs.knot}/bin/knotd";
      User = "knot";
      PermissionsStartOnly = true;
    };
  };

  users.extraUsers.knot = {
    uid = config.ids.uids.knot;
    description = "knot daemon user";
  };
}

{ config, lib, pkgs, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  outboundIp = "${calculated.myNetMap.pub4}${toString calculated.myNetMap.pub4MachineMap.outbound}";
in
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

    # Rewrite traffic to gandi and no-ip to the correct ip
    iptables -t mangle -A OUTPUT -m owner --uid-owner knot -p tcp --dport 53 -j MARK --set-mark 0x20
    ip route del table 10 default || true
    ip route add table 10 default via ${calculated.myGatewayIp4}
    ip rule del fwmark 0x20 || true
    ip rule add fwmark 0x20 table 10
    iptables -t nat -A POSTROUTING -m mark --mark 0x20 -j LOG
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

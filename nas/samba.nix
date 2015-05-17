{ config, lib, pkgs, ... }:

with lib;
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  net = calculated.myNasIps;
in
{
  imports = [ ../core/ctdbd.nix ];

  networking.firewall.extraCommands = mkMerge [
    (flip concatMapStrings [ "mlan" "dlan" ] (n: ''
      # Samba ports
      ip46tables -A INPUT -i ${n} -p tcp --dport 135 -j ACCEPT
      ip46tables -A INPUT -i ${n} -p tcp --dport 139 -j ACCEPT
      ip46tables -A INPUT -i ${n} -p tcp --dport 445 -j ACCEPT
      ip46tables -A INPUT -i ${n} -p udp --dport 137 -j ACCEPT
      ip46tables -A INPUT -i ${n} -p udp --dport 138 -j ACCEPT
    ''))
    (mkAfter (flip concatMapStrings calculated.myNetMap.nases (n: ''
      ipset add ctdb "${calculated.vpnIp4 n}"
    '')))
  ];

  environment.etc."ctdb/public_addresses".text =
    flip concatMapStrings calculated.myNasIp4s (n: ''
      ${n}/24 dlan
    '');

  environment.etc."ctdb/nodes".text =
    flip concatMapStrings calculated.myNetMap.nases (n: ''
      ${calculated.vpnIp4 n}
    '');

  environment.systemPackages = with pkgs; [ samba ];

  services.samba = {
    enable = true;
    syncPasswordsByPam = true;
    extraConfig = ''
      workgroup = ${calculated.myDomain}
      server string = %h
      security = user
      load printers = no
      guest account = nobody
      invalid users = root
      log level = 1
      log file = /var/log/samba/log.%m
      max log size = 5000
      passdb backend = tdbsam
      local master = no
      preferred master = yes
      dns proxy = no
      store dos attributes = yes
      map hidden = no
      map system = no
      map archive = no
      nt acl support = yes
      inherit acls = yes
      map acl inherit = yes
      encrypt passwords = yes
      client plaintext auth = no

      # Clustered storage setup
      netbios name = ${calculated.myDomain}
      clustering = yes
      idmap config * : backend = tdb2
      fileid : algorithm = fsid

      # Performance
      socket options = TCP_NODELAY SO_SNDBUF=131072 SO_RCVBUF=131072
      use sendfile = yes
      min receivefile size = 16384
      aio read size = 16384
      aio write size = 16384

      [Private]
        vfs objects = acl_xattr fileid aio_linux
        path = /ceph/share/private/%u
        guest ok = no
        public = no
        writable = yes
        printable = no
        create mask = 0600
        force create mode = 0600
        directory mask = 0700
        force directory mode = 0700
        force group = share
      [Public]
        vfs objects = acl_xattr fileid aio_linux
        path = /ceph/share/public
        guest ok = no
        writable = yes
        printable = no
        create mask = 0660
        force create mode = 0660
        directory mask = 0770
        force directory mode = 0770
        force group = share
        force user = nobody
      [Read Only]
        vfs objects = acl_xattr fileid aio_linux
        path = /ceph/share/ro
        guest ok = no
        writable = yes
        printable = no
        create mask = 0640
        force create mode = 0640
        directory mask = 0750
        force directory mode = 0750
        force group = share
    '';
  };

  systemd.services.samba-smbd.after = [ "ctdbd.service" ];
  systemd.services.samba-nmbd.after = [ "ctdbd.service" ];
}

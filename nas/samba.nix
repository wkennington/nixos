{ config, lib, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  shareDir = "/ceph/share";
in
{
  networking.firewall.extraCommands = ''
    ip46tables -A INPUT -i dlan -p tcp --dport 135 -j ACCEPT
    ip46tables -A INPUT -i dlan -p tcp --dport 139 -j ACCEPT
    ip46tables -A INPUT -i dlan -p tcp --dport 445 -j ACCEPT
    ip46tables -A INPUT -i dlan -p udp --dport 137 -j ACCEPT
    ip46tables -A INPUT -i dlan -p udp --dport 138 -j ACCEPT
  '';
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

      # Performance
      socket options = TCP_NODELAY SO_SNDBUF=131072 SO_RCVBUF=131072
      use sendfile = yes
      min receivefile size = 16384
      aio read size = 16384
      aio write size = 16384

      [Private]
        path = ${shareDir}/private/%u
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
        path = ${shareDir}/public/
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
        path = ${shareDir}/ro/
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
}

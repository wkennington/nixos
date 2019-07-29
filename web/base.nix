{ config, lib, pkgs, ... }:

with lib;
{
  require = [
    ./sub/acme-settings.nix
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    package = pkgs.nginx;
    config = mkMerge [
      (mkBefore (''
        worker_processes 4;
        events {
          worker_connections 1024;
        }
        http {
          include ${config.services.nginx.package}/etc/nginx/mime.types;
          default_type application/octet-stream;
          sendfile on;
          tcp_nopush on;
          aio threads;
          directio 4m;
          output_buffers 1 64k;
          keepalive_timeout 60;

          upstream acme {
      '' + flip concatMapStrings config.acmeServers (n: ''
            server ${n};
      '') + ''
          }

          server {
            listen *:80;
            listen [::]:80;
            server_name default;
            location / {
              root ${config.services.nginx.package}/share/nginx/html;
              index index.html;
            }
            location /.well-known/acme-challenge {
              proxy_pass http://acme;
            }
            error_page 500 502 503 504 /50x.html;
          }
          server {
            listen *:443 ssl http2;
            listen [::]:443 ssl http2;
            server_name default;
            location / {
              root ${config.services.nginx.package}/share/nginx/html;
              index index.html;
            }
            error_page 500 502 503 504 /50x.html;

            ${import sub/ssl-settings.nix { domain = "nginx/default"; }}
          }
      ''))
      (mkAfter ''
        }
      '')
    ];
  };
  systemd.services.nginx = {
    wants = [ "ceph.mount" ];
    after = [ "ceph.mount" ];
  };

  environment.etc."consul.d/web-base.json".text = builtins.toJSON {
    check = {
      id = "web-base";
      name = "Nginx Serving Default";
      http = "http://localhost";
      interval = "10s";
      timeout = "1s";
    };
  };
}

{ config, lib, pkgs, ... }:

with lib;
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    config = mkMerge [
      (mkBefore ''
        worker_processes 4;
        events {
          worker_connections 1024;
        }
        http {
          include ${config.services.nginx.package}/etc/nginx/mime.types;
          default_type application/octet-stream;
          sendfile off;
          aio on;
          output_buffers 1 64k;
          keepalive_timeout 60;
          server {
            listen 80;
            server_name default;
            location / {
              root ${config.services.nginx.package}/share/nginx/html;
              index index.html;
            }
            error_page 500 502 503 504 /50x.html;
          }
          server {
            listen 443;
            server_name default;
            location / {
              root ${config.services.nginx.package}/share/nginx/html;
              index index.html;
            }
            error_page 500 502 503 504 /50x.html;

            ${import sub/ssl-settings.nix { domain = "nginx/default"; }}
          }
      '')
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
      script = ''
        if ${pkgs.curl}/bin/curl http://localhost; then
          exit 0
        fi
        exit 1 # Warning
      '';
      interval = "60s";
    };
  };
}

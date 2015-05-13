{ config, lib, pkgs, ... }:

with lib;
{
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    extraCommands = ''
      # Allow consul checks to happen
      ip46tables -A OUTPUT -m owner --uid-owner consul -o lo -p tcp --dport 80 -j ACCEPT
      ip46tables -A OUTPUT -m owner --uid-owner consul -o lo -p tcp --dport 443 -j ACCEPT
    '';
  };

  services.nginx = {
    enable = true;
    config = mkMerge [
      (mkBefore ''
        worker_processes 4;
        events {
          worker_connections 1024;
        }
        http {
          include ${config.services.nginx.package}/conf/mime.types;
          default_type application/octet-stream;
          sendfile off;
          aio on;
          output_buffers 1 64k;
          keepalive_timeout 60;
          server {
            listen 80;
            server_name default;
            location / {
              root ${config.services.nginx.package}/html;
              index index.html;
            }
            error_page 500 502 503 504 /50x.html;
          }
          server {
            listen 443;
            server_name default;
            location / {
              root ${config.services.nginx.package}/html;
              index index.html;
            }
            error_page 500 502 503 504 /50x.html;

            ssl on;
            ssl_protocols TLSv1.2;
            ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
            ssl_ecdh_curve secp521r1;
            ssl_prefer_server_ciphers on;
            ssl_dhparam /conf/ssl/nginx/dhparam;
            ssl_certificate /conf/ssl/nginx/default.crt;
            ssl_certificate_key /conf/ssl/nginx/default.key;
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
        exit 2
      '';
      interval = "60s";
    };
  };
}

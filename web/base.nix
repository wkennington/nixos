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
}

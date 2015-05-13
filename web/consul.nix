{ config, pkgs, lib, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  constants = (import ../common/sub/constants.nix { });

  domain = "consul.${calculated.myDomain}";
in
with lib;
{
  imports = [
    ../common/consul.nix
  ];

  networking.firewall.extraCommands = ''
    # Allow nginx to access consul http
    ip46tables -A OUTPUT -o lo -m owner --uid-owner nginx -p tcp --dport 8500 -j ACCEPT
  '';

  services = {
    consul.webUi = true;
    nginx.config = ''
      server {
        listen 443;
        server_name ${domain};
        location / {
          proxy_set_header Accept-Encoding "";
          proxy_set_header Host $http_host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;

          proxy_pass http://localhost:8500/;
          proxy_set_header Front-End-Https on;
          proxy_redirect off;

          limit_except GET {
            deny all;
          }
        }

        ssl on;
        ssl_protocols TLSv1.2;
        ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
        ssl_ecdh_curve secp521r1;
        ssl_prefer_server_ciphers on;
        ssl_dhparam /conf/ssl/nginx/dhparam;
        ssl_certificate /conf/ssl/${domain}.crt;
        ssl_certificate_key /conf/ssl/${domain}.key;
        add_header Strict-Transport-Security "max-age=31536000";
      }

      server {
        listen 80;
        server_name ${domain};
        rewrite ^(.*) https://${domain}$1 permanent;
      }
    '';
  };
}

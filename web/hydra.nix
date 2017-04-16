{ lib, ... }:
let
  vars = (import ./customization/vars.nix { inherit lib; });

  domain = "hydra.${vars.domain}";
  hydraInstance = "10.1.2.30:3000";
in
{
  services.nginx.config = ''
    server {
      listen [::]:443 ssl http2;
      server_name ${domain};
      location / {
        proxy_set_header Accept-Encoding "";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_pass http://${hydraInstance}/;
        proxy_set_header Front-End-Https on;
        proxy_redirect off;
      }

      ${import sub/ssl-settings.nix { inherit domain; }}
    }

    server {
      listen [::]:80;
      server_name ${domain};
      rewrite ^(.*) https://${domain}$1 permanent;
    }
  '';
}

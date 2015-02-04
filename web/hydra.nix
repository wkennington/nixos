{ lib, ... }:
let
  vars = (import ./customization/vars.nix { inherit lib; });

  domain = "hydra.${vars.domain}";
  hydraInstance = "10.1.2.30:3000";
in
{
  services.nginx.config = ''
    server {
      listen 443;
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

      ssl on;
      ssl_protocols TLSv1.2;
      ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
      ssl_ecdh_curve secp521r1;
      ssl_prefer_server_ciphers on;
      ssl_dhparam /conf/ssl/nginx/dhparam;
      ssl_certificate /conf/ssl/nginx/${domain}.crt;
      ssl_certificate_key /conf/ssl/nginx/${domain}.key;
    }

    server {
      listen 80;
      server_name ${domain};
      rewrite ^(.*) https://${domain}$1 permanent;
    }
  '';
}

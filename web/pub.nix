{ lib, ... }:
let
  vars = (import ../customization/vars.nix { inherit lib; });

  domain = "pub.${vars.domain}";
  path = "/ceph/www-pub";
in
{
  imports = [ ./base.nix ];
  services.nginx.config = ''
    server {
      listen 443;
      server_name ${domain};

      location / {
        root ${path};
        autoindex on;
      }
      error_page 500 502 503 504 /50x.html;

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

      location / {
        root ${path};
        autoindex on;
      }

      error_page 500 502 503 504 /50x.html;
    }
  '';
}

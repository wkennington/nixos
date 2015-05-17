{ config, lib, pkgs, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  vars = (import ../customization/vars.nix { inherit lib; });

  domain = "pub.${vars.domain}";
  consulService = "pub";
  consulDomain = "${consulService}.service.consul.${vars.domain}";
  checkDomain = "${consulService}.${config.networking.hostName}.${vars.domain}";

  path = "/ceph/www-pub";
in
{
  imports = [ ./base.nix ];
  services.nginx.config = ''
    server {
      listen 443;
      server_name ${domain};
      server_name ${consulDomain};
      server_name ${checkDomain};

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
      server_name ${consulDomain};

      location / {
        root ${path};
        autoindex on;
      }

      error_page 500 502 503 504 /50x.html;
    }
  '';

  environment.etc."consul.d/${consulService}.json".text = builtins.toJSON {
    service = {
      name = consulService;
      port = 443;
      checks = [
        {
          script = ''
            export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
            # TODO: Get a new cert and remove -k
            if ${pkgs.curl}/bin/curl -k https://${checkDomain}/; then
              exit 0
            fi
            exit 2 # Critical
          '';
          interval = "60s";
        }
      ];
    };
  };
}

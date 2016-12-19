{ config, lib, pkgs, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  vars = (import ../customization/vars.nix { inherit lib; });

  domain = "mumble.${calculated.myDomain}";
  topDomain = "mumble.${vars.domain}";
  consulService = "mumble-web";
  consulDomain = "${consulService}.service.consul.${vars.domain}";
  checkDomain = "${consulService}.${config.networking.hostName}.${vars.domain}";

  path = "/ceph/www-mumble";
in
{
  imports = [ ./base.nix ];

  services.nginx.config = ''
    server {
      listen 443 ssl http2;
      server_name ${domain};
      server_name ${topDomain};
      server_name ${consulDomain};
      server_name ${checkDomain};

      location / {
        root ${path};
        autoindex on;
        autoindex_exact_size off;
      }

      location /.well-known/acme-challenge {
        alias /var/lib/acme;
        expires -1;
        autoindex on;
      }

      error_page 500 502 503 504 /50x.html;

      ${import sub/ssl-settings.nix { inherit domain; }}
    }

    server {
      listen 80;
      server_name ${domain};
      server_name ${topDomain};
      server_name ${consulDomain};
      server_name ${checkDomain};

      location / {
        root ${path};
        autoindex on;
        autoindex_exact_size off;
      }

      location /.well-known/acme-challenge {
        alias /var/lib/acme;
        expires -1;
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

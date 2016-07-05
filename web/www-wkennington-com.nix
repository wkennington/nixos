{ config, lib, pkgs, ... }:
let
  inherit (lib)
    concatMapStrings
    head
    flip;

  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  vars = (import ../customization/vars.nix { inherit lib; });

  consulService = "www-wkennington-com";
  consulDomain = "${consulService}.service.consul.${vars.domain}";
  checkDomain = "${consulService}.${config.networking.hostName}.${vars.domain}";

  dc = calculated.dc config.networking.hostName;

  domains = [
    "www.${dc}.wkennington.com"
    "${dc}.wkennington.com"
    "www.wkennington.com"
    "wkennington.com"
    consulDomain
    checkDomain
  ];

  path = "/ceph/${consulService}";
in
{
  imports = [ ./base.nix ];

  services.nginx.config = ''
    server {
      listen 443 ssl http2;
  '' + flip concatMapStrings domains (n: ''
      server_name ${n};
  '') + ''

      location / {
        root ${path};
        autoindex on;
      }

      location /.well-known/acme-challenge/ {
        root /var/lib/letsencrypt/www/.well-known/acme-challenge;
        autoindex off;
      }

      error_page 500 502 503 504 /50x.html;

      ${import sub/ssl-settings.nix { domain = head domains; }}
    }

  '' + flip concatMapStrings domains (n: ''
    server {
      listen 80;
      server_name ${n};

      location / {
        rewrite ^(.*) https://${n}$1 permanent;
      }

      location /.well-known/acme-challenge/ {
        root /var/lib/letsencrypt/www/.well-known/acme-challenge;
        autoindex off;
      }
    }
  '');

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

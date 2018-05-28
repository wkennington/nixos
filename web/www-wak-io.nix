{ config, lib, pkgs, ... }:
let
  inherit (lib)
    concatMapStrings
    head
    flip;

  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  vars = (import ../customization/vars.nix { inherit lib; });

  consulService = "www-wak-io";
  consulDomain = "${consulService}.service.consul.${vars.domain}";
  checkDomain = "${consulService}.${config.networking.hostName}.${vars.domain}";

  dc = calculated.dc config.networking.hostName;

  domains = [
    "www.${dc}.wak.io"
    "${dc}.wak.io"
    "www.wak.io"
    "wak.io"
    consulDomain
    checkDomain
  ];

  path = "/ceph/${consulService}";
in
{
  imports = [ ./base.nix ];

  services.nginx.config = ''
    server {
      listen *:443 ssl http2;
      listen [::]:443 ssl http2;
  '' + flip concatMapStrings domains (n: ''
      server_name ${n};
  '') + ''

      location / {
        root ${path};
        autoindex on;
      }

      location /.well-known/acme-challenge {
        alias /var/lib/acme;
        expires -1;
        autoindex on;
      }

      error_page 500 502 503 504 /50x.html;

      ${import sub/ssl-settings.nix { domain = head domains; }}
    }

  '' + flip concatMapStrings domains (n: ''
    server {
      listen *:80;
      listen [::]:80;
      server_name ${n};

      location / {
        rewrite ^(.*) https://${n}$1 permanent;
      }

      location /.well-known/acme-challenge {
        alias /var/lib/acme;
        expires -1;
        autoindex on;
      }
    }
  '');

  environment.etc."consul.d/${consulService}.json".text = builtins.toJSON {
    service = {
      name = consulService;
      port = 443;
      checks = [
        {
          http = "https://${checkDomain}:443";
          tls_skip_verify = true;
          interval = "10s";
          timeout = "1s";
        }
      ];
    };
  };
}

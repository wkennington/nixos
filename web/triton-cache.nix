{ config, lib, pkgs, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  vars = (import ../customization/vars.nix { inherit lib; });

  domain = "cache.triton.${calculated.myDomain}";
  topDomain = "cache.triton.${vars.domain}";
  consulService = "triton-cache";
  consulDomain = "${consulService}.service.consul.${vars.domain}";
  checkDomain = "${consulService}.${config.networking.hostName}.${vars.domain}";

  path = "/ceph/triton-cache";
in
{
  imports = [ ./base.nix ];

  services.nginx.config = ''
    server {
      listen *:443 ssl http2;
      listen [::]:443 ssl http2;
      server_name ${domain};
      server_name ${topDomain};
      server_name ${consulDomain};
      server_name ${checkDomain};

      location / {
        root ${path};
        autoindex off;
        autoindex_exact_size off;
      }

      error_page 500 502 503 504 /50x.html;

      ${import sub/ssl-settings.nix { inherit domain; }}
    }

    server {
      listen *:80;
      listen [::]:80;
      server_name ${domain};
      server_name ${topDomain};
      server_name ${consulDomain};
      server_name ${checkDomain};

      location / {
        root ${path};
        autoindex off;
        autoindex_exact_size off;
      }

      location /.well-known/acme-challenge {
        proxy_pass http://acme;
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
          http = "https://${checkDomain}:443";
          tls_skip_verify = true;
          interval = "10s";
          timeout = "1s";
        }
      ];
    };
  };
}

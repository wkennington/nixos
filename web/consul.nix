{ config, pkgs, lib, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  constants = (import ../common/sub/constants.nix { });
  vars = (import ../customization/vars.nix { inherit lib; });

  domain = "consul.${calculated.myDomain}";
  topDomain = "consul.${vars.domain}";
  consulService = "consul-web";
  consulDomain = "${consulService}.service.consul.${vars.domain}";
  checkDomain = "${consulService}.${config.networking.hostName}.${vars.domain}";
in
with lib;
{
  imports = [
    ./base.nix
    ../common/consul.nix
  ];

  networking.firewall.extraCommands = ''
    # Allow nginx to access consul http
    ip46tables -A OUTPUT -o lo -m owner --uid-owner nginx -p tcp --dport 8500 -j ACCEPT
  '';

  networking.extraHosts = ''
    ${calculated.myInternalIp4} ${checkDomain}
  '';

  services = {
    consul.webUi = true;
    nginx.config = ''
      server {
        listen 443 ssl http2;
        server_name ${domain};
        server_name ${topDomain};
        server_name ${consulDomain};
        server_name ${checkDomain};

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

        location /.well-known/acme-challenge {
          alias /var/lib/acme;
          expires -1;
          autoindex on;
        }

        ${import sub/ssl-settings.nix { inherit domain; }}
      }

      server {
        listen 80;
        server_name ${domain};

        location / {
          rewrite ^(.*) https://${domain}$1 permanent;
        }

        location /.well-known/acme-challenge {
          alias /var/lib/acme;
          expires -1;
          autoindex on;
        }

      }

      server {
        listen 80;
        server_name ${consulDomain};

        location / {
          rewrite ^(.*) https://${consulDomain}$1 permanent;
        }

        location /.well-known/acme-challenge {
          alias /var/lib/acme;
          expires -1;
          autoindex on;
        }

      }

      server {
        listen 80;
        server_name ${topDomain};

        location / {
          rewrite ^(.*) https://${topDomain}$1 permanent;
        }

        location /.well-known/acme-challenge {
          alias /var/lib/acme;
          expires -1;
          autoindex on;
        }

      }
    '';
  };

  environment.etc."consul.d/${consulService}.json".text = builtins.toJSON {
    service = {
      name = consulService;
      port = 443;
      checks = [
        {
          script = ''
            export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
            # TODO: Get a new cert and remove -k
            if ${pkgs.curl}/bin/curl -k https://${checkDomain}/ui/; then
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

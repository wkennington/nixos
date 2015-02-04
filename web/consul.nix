{ pkgs, lib, ... }:
let
  vars = (import ../customization/vars.nix { inherit lib; });
  constants = (import ../common/sub/constants.nix { });

  domain = "consul.${vars.domain}";
in
with lib;
{
  imports = [ ../common/consul.nix ];
  services = {
    consul.webUi = true;
    nginx.config = ''
      server {
        listen 443;
        server_name ${domain};
        location / {
          ${flip concatMapStrings constants.privateIp4 (ip: ''
            allow ${ip};
          '')}
          deny all;

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
        ssl_dhparam /etc/nixos/nginx/dhparam;
        ssl_certificate /etc/nixos/nginx/${domain}.crt;
        ssl_certificate_key /etc/nixos/nginx/${domain}.key;
      }

      server {
        listen 80;
        server_name ${domain};
        rewrite ^(.*) https://${domain}$1 permanent;
      }
    '';
  };
  systemd.services.consul-dash = {
    wantedBy = [ "multi-user.target" ];
    after = [ "nginx.service" "consul-client-rpc.socket" ];
    bindsTo = [ "nginx.service" "consul.service" ];
    path = [ pkgs.curl ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "nobody";
    };

    script = ''
      COUNT=10
      while [ "$COUNT" -gt "0" ]; do
        if curl -X PUT http://127.0.0.1:8500/v1/agent/service/register \
          -d '{ "ID": "consul-dash", "Name": "consul-dash", "Port": 80 }'; then
          break
        fi
        sleep 1
        COUNT="$(($COUNT - 1))"
      done
    '';

    postStop = ''
      curl -X PUT http://127.0.0.1:8500/v1/agent/service/deregister/consul-dash
    '';
  };
}

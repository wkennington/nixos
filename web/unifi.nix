{ config, lib, ... }:
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  constants = (import ../common/sub/constants.nix { });

  domain = "unifi.${calculated.myDomain}";
  host = if calculated.iAmRemote then calculated.myVpnIp4 else calculated.internalIp4 vars.host "slan";
in
with lib;
{
  imports = [ ./base.nix ];

  networking.extraHosts = ''
    ${host} ${domain}
  '';

  networking.firewall.extraCommands = ''
    # Allow access points to attach to the controller
    ip46tables -A INPUT -i mlan -p tcp --dport 8080 -j ACCEPT

    # Allow nginx to access unifi
    ip46tables -A OUTPUT -o lo -m owner --uid-owner nginx -p tcp --dport 8443 -j ACCEPT

    # Allow unifi to access mongodb
    ip46tables -A OUTPUT -o lo -m owner --uid-owner unifi -p tcp --dport 27117 -j ACCEPT
  '';

  nixpkgs.config.allowUnfree = true;

  services = {
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

          proxy_pass https://localhost:8443/;
          proxy_set_header Front-End-Https on;
          proxy_redirect off;
        }

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
        rewrite ^(.*) https://${domain}$1 permanent;
      }
    '';

    unifi.enable = true;
  };
}

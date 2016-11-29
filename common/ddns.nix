{ config, lib, pkgs, ... }:

let
  inherit (lib)
    length;

  vars = (import ../customization/vars.nix { inherit lib; });

  host = "${config.networking.hostName}.${vars.domain}";

  stateDir = "/var/lib/ddclient";
in
{
  systemd.services."${host}-update" = {
    wantedBy = [
      "multi-user.target"
    ];
    wants = [
      "network-online.target"
    ];
    after = [
      "network-online.target"
    ];

    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "5s";
      RestartPreventExitStatus = "80";
      User = "ddclient";
    };
    
    path = [
      pkgs.coreutils
      pkgs.curl
      pkgs.bind_tools
      pkgs.gawk
      pkgs.gnugrep
      pkgs.knot
    ];
    
    script = ''
      set -e
      set -o pipefail

      # Make sure we can open our key file
      cat "/conf/ddns/${host}.key" >/dev/null || exit 80

      ip4="$(curl -4 -s "https://ifconfig.co")"
      if echo "$ip4" | grep -q 'Too Many Requests'; then
        echo "Too many attempts, waiting 60 seconds"
        sleep 60
        exit 1
      fi
      echo "Request got: $ip4" >&2
      echo "$ip4" | grep -q '^[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}''$'

      nameserver="$(dig NS wak.io | grep 'IN\s\+NS\s\+' | awk '{print $5}' | head -n 1)"
      echo "Using nameserver: $nameserver" >&2

      commands="server $nameserver\n"
      commands+="ttl 300\n"
      commands+="zone ${host}.\n"
      commands+="origin ${host}.\n"
      commands+="del ${host}.\n"
      commands+="add ${host}. A $ip4\n"
      commands+="send\n"
      echo -n -e "$commands" | knsupdate -t 10 -r 3 -k "/conf/ddns/${host}.key"
    '';
  };

  systemd.timers."${host}-update" = {
    wantedBy = [ "multi-user.target" ];

    timerConfig = {
      OnUnitActiveSec = "5m";
    };
  };

  users.extraUsers.ddclient = {
    uid = config.ids.uids.ddclient;
    description = "ddclient daemon user";
    home = stateDir;
  };
}

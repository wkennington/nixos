{ config, lib, pkgs, ... }:

let
  calculated = (import ./calculated.nix { inherit config lib; });

  timeSyncdScript = pkgs.writeScript "osd-script" ''
    #! ${pkgs.stdenv.shell} -e
    export PATH="${pkgs.chrony}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin"
    out="$(chronyc tracking)"
    echo "$out" >&2
    chronyc sourcestats
    if [ "$(echo "$out" | awk -F'[ ]*:[ ]*' '/Stratum/{print $2;}')" -eq "0" ]; then
      exit 1
    fi
    if ! echo "$out" | awk -F'[ ]*:[ ]*' '/System time/{print $2;}' | grep -q '^0.000'; then
      exit 1
    fi
    exit 0
  '';
in
with lib;
{
  services = {
    ntp = {
      servers = map ({ server, weight}: server) calculated.myNtpServers;
    };
    chrony = {
      enable = true;
      extraConfig = ''
        leapsecmode slew
        maxslewrate 1000
        smoothtime 400 0.001
        leapsectz right/UTC
      '';
    };
  };

  networking.firewall.extraCommands = ''
    ip46tables -A OUTPUT -m owner --uid-owner chrony -p udp --dport ntp -j ACCEPT
  '';

  systemd.targets.time-syncd = {
    description = ''
      This target is met when the time is in sync
      with upstream servers.
    '';
    requires = [
      "time-syncd.service"
    ];
    after = [
      "time-syncd.service"
    ];
  };

  systemd.services.time-syncd = {
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "0";
    };

    script = ''
      while ! ${timeSyncdScript}; do
        sleep 5
      done
    '';
  };

  environment.etc."consul.d/chronyd.json".text = builtins.toJSON {
    check = {
      id = "chronyd";
      name = "Chrony Clock Sync";
      script = ''
        if ! ${timeSyncdScript}; then
          exit 2 # Critical Error
        fi
        exit 0
      '';
      interval = "10s";
    };
  };

  systemd.services.chronyd.postStart = lib.optionalString config.services.consul.enable ''
    while [ ! -e "/run/chrony/chronyd.sock" ]; do
      sleep 1
    done
    ${pkgs.acl}/bin/setfacl -m u:consul:rw /run/chrony/chronyd.sock
  '';
}

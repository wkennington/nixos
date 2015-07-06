{ config, lib, pkgs, ... }:
let
  calculated = (import ./calculated.nix { inherit config lib; });
in
{
  services = {
    ntp = {
      enable = false;
      servers = calculated.myNtpServers;
    };
    openntpd = {
      enable = true;
      extraOptions = "-s";
    };
  };

  networking.firewall.extraCommands = ''
    ip46tables -A OUTPUT -m owner --uid-owner ntp -p udp --dport ntp -j ACCEPT
  '';

  systemd.targets.time-syncd = {
    requires = [ "time-syncd.service" ];
    after = [ "time-syncd.service" ];
  };

  systemd.services.time-syncd = {
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "0";
    };

    path = with pkgs; [ gnugrep openntpd ];

    script = ''
      while true; do
        if ntpctl -s status | grep -q 'clock synced'; then
          exit 0
        fi
        sleep 30
      done
    '';
  };

  systemd.timers.check-ntpd = {
    wantedBy = [ "timers.target" ];
    requires = [ "openntpd.service" ];
    bindsTo = [ "openntpd.service" ];

    timerConfig = {
      OnActiveSec = 60;
      OnUnitActiveSec = 60;
    };
  };

  systemd.services.check-ntpd = {
    requires = [ "openntpd.service" ];
    after = [ "openntpd.service" ];

    serviceConfig = {
      Type = "oneshot";
    };

    path = with pkgs; [ gnugrep openntpd systemd ];

    script = ''
      if ntpctl -s all | grep -q 'not resolved'; then
        systemctl restart openntpd
      fi
    '';
  };

  environment.etc."consul.d/openntpd.json".text = builtins.toJSON {
    check = {
      id = "openntpd";
      name = "Openntpd Clock Sync";
      script = ''
        OUT="$(${pkgs.openntpd}/bin/ntpctl -s all)"
        echo "$OUT"
        if echo "$OUT" | ${pkgs.gnugrep}/bin/grep -q 'clock synced'; then
          exit 0
        fi
        exit 2 # Critical Error
      '';
      interval = "60s";
    };
  };

  systemd.services.openntpd.postStart = lib.optionalString config.services.consul.enable ''
    ${pkgs.acl}/bin/setfacl -m u:consul:rw /run/ntpd.sock
  '';
}

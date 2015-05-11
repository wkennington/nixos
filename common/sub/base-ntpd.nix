{ pkgs, ... }:
{
  services = {
    ntp.enable = false;
    openntpd = {
      enable = true;
      extraOptions = "-s";
    };
  };

  networking.firewall.extraCommands = ''
    ip46tables -A OUTPUT -m owner --uid-owner ntp -p udp --dport ntp -j ACCEPT
  '';

  systemd.targets.time-syncd = {};

  systemd.services.openntpd.postStart = ''
    if ntpctl -s status | grep -q 'clock synced'; then
      systemctl start time-syncd.target
    fi
  '';

  systemd.timers.check-ntpd = {
    wantedBy = [ "timers.target" ];
    requires = [ "openntpd.service" ];
    bindsTo = [ "openntpd.service" ];

    timerConfig = {
      OnActiveSec = 120;
      OnUnitActiveSec = 120;
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
      if ntpctl -s status | grep -q 'clock synced'; then
        systemctl start time-syncd.target
      fi
      if ntpctl -s all | grep -q 'not resolved'; then
        systemctl restart openntpd
      fi
    '';
  };
}

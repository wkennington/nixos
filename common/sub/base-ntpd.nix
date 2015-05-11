{ pkgs, ... }:
{
  services = {
    ntp.enable = false;
    openntpd.enable = true;
  };

  networking.firewall.extraCommands = ''
    ip46tables -A OUTPUT -m owner --uid-owner ntp -p udp --dport ntp -j ACCEPT
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
      if ntpctl -s all | grep -q 'not resolved'; then
        systemctl restart openntpd
      fi
    '';
  };
}

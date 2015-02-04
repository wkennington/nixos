{ config, pkgs, ... }:
{
  imports = [
    ./postgresql.nix
  ];
  networking.firewall.extraCommands = ''
    # Allow all access
    ip46tables -A INPUT -p tcp --dport 4242 -j ACCEPT

    # DB Access
    ip46tables -A OUTPUT -m owner --uid-owner quassel -o lo -p tcp --dport 5432 -j ACCEPT
  '';
  services.quassel = {
    enable = true;
    dataDir = "/var/lib/quassel";
    interface = "0.0.0.0";
  };
  systemd.services.quassel.serviceConfig.Restart = "always";
}

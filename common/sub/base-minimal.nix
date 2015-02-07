{ lib, ... }:
with lib;
{
  fonts.fontconfig.enable = mkDefault false;
  hardware.pulseaudio.enable = mkDefault false;
  programs.ssh = {
    setXAuthLocation = mkDefault false;
    startAgent = mkDefault false;
  };
  security = {
    pam.services.su.forwardXAuth = mkDefault false;
    sudo.enable = mkDefault false;
  };
  services = {
    nscd.enable = mkDefault false;
    cron.enable = mkDefault false;
  };
  sound.enable = mkDefault false;
}

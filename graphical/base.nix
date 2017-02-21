{ pkgs, lib, ... }:
with lib;
{
  # Undo minimalistic settings
  fonts.fontconfig.enable = true;
  hardware.pulseaudio.enable = true;
  security.pam.services.su.forwardXAuth = true;
  sound.enable = true;

  environment.systemPackages = [
    pkgs.flashrom
    pkgs.slock
  ];
  security.sudo.enable = true;
  services = {
    kmscon.hwRender = true;
    pcscd = {
      enable = true;
      allowedGroups = [ "users" ];
    };
    udev.packages = [
      pkgs.libu2f-host
    ];
    xserver = {
      enable = true;
      windowManager.default = "none";
      desktopManager.default = "none";
      displayManager.lightdm.enable = true;
    };
  };
  security.setuidPrograms = [ "slock" ];
}

{ pkgs, lib, ... }:
with lib;
{
  # Undo minimalistic settings
  fonts.fontconfig.enable = true;
  hardware.pulseaudio.enable = true;
  security.pam.services.su.forwardXAuth = true;
  sound.enable = true;

  environment.systemPackages = [ pkgs.slock ];
  services = {
    kmscon.hwRender = true;
    pcscd.enable = true;
    xserver = {
      enable = true;
      windowManager.default = "none";
      desktopManager.default = "none";
      displayManager.lightdm.enable = true;
    };
  };
  security.setuidPrograms = [ "slock" ];
}

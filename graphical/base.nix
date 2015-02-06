{ pkgs, lib, ... }:
with lib;
{
  environment.systemPackages = [ pkgs.slock ];
  fonts.fontconfig.enable = mkOverride 1 true;
  hardware.pulseaudio.enable = true;
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

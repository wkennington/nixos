{ config, pkgs, ... }:
{
  imports = [ ./base.nix ];
  nixpkgs.config.allowUnfree = true;
  services.kmscon.enable = false;
  services.xserver = {
    vaapiDrivers = [ pkgs.vaapi-vdpau ];
    videoDrivers = [ "nvidia-long" ];
  };
}

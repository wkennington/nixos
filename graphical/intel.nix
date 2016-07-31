{ config, pkgs, ... }:
{
  imports = [ ./base.nix ];
  hardware.opengl.s3tcSupport = true;
  services.kmscon.enable = false;
  services.xserver = {
    vaapiDrivers = [ pkgs.vaapi-intel ];
    videoDrivers = [ "modesetting" ];
  };
}

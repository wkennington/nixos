{ config, pkgs, ... }:
{
  imports = [ ./base.nix ];
  services.kmscon.enable = true;
  services.xserver = {
    vaapiDrivers = [ pkgs.vaapi-intel ];
    videoDrivers = [ "intel" ];
  };
}

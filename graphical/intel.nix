{ config, pkgs, ... }:
{
  imports = [ ./base.nix ];
  services.kmscon.enable = false;
  services.xserver = {
    vaapiDrivers = [ pkgs.intel-vaapi-driver ];
    videoDrivers = [ "modesetting" ];
  };
}

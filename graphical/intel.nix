{ config, pkgs, ... }:
{
  imports = [ ./base.nix ];
  services.kmscon.enable = true;
  services.xserver = {
    vaapiDrivers = [ pkgs.vaapiIntel ];
    videoDrivers = [ "intel" ];
  };
}

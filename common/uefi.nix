{ config, pkgs, ... }:
{
  boot = {
    initrd.kernelModules = [ "fbcon" ];
    loader.grub.enable = false;
    loader.gummiboot = {
      enable = true;
      timeout = 1;
    };
  };
}

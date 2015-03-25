{ config, pkgs, ... }:
{
  boot = {
    initrd.kernelModules = [ "fbcon" ];
    loader.efi.canTouchEfiVariables = true;
    loader.grub.enable = false;
    loader.gummiboot = {
      enable = true;
      timeout = 1;
    };
  };
}

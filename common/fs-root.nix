{ config, lib, ... }:
with lib;
{
  boot = {
    initrd.kernelModules = [ "fbcon" ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub.efiSupport = true;
    };
  };

  fileSystems = mkOrder 1 [
    {
      mountPoint = "/boot";
      device = "${config.boot.loader.grub.device}-part2";
      fsType = "vfat";
      options = "defaults,noatime";
      neededForBoot = true;
    }
  ];
}

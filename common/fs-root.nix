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

  fileSystems = mkOrder 1 (flip map config.boot.loader.grub.mirroredBoots
    (arg:
    assert arg.path != "/boot"; # We should never see the default path
    assert length arg.devices == 1; # There should always be a 1 - 1 map between paths and devices
    {
      mountPoint = arg.path;
      device = "${head arg.devices}-part2";
      fsType = "vfat";
      options = "defaults,noatime";
      neededForBoot = true;
    }));
}

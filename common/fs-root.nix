{ config, lib, pkgs, ... }:
with lib;
{
  boot = {
    kernelParams = [ "console=tty0 console=ttyS1,115200n8" ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        efiSupport = true;
        extraConfig = ''
          serial --unit=1 --speed=115200
          terminal_input --append serial
          terminal_output --append serial
        '';
      };
      timeout = 1;
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

  system.extraDependencies = with pkgs; [
    grub2 grub2_efi
  ];
}

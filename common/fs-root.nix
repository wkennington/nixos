{ config, lib, pkgs, ... }:with lib;
{
  require = [
    ./sub/fs-root-module.nix
  ];
  boot = {
    kernelParams = optionals (config.serialConsole != null) [
      "console=tty0"
      "console=ttyS${toString config.serialConsole},115200n8"
    ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        efiSupport = true;
        extraConfig = optionalString (config.serialConsole != null) ''
          serial --unit=${toString config.serialConsole} --speed=115200
          terminal_input --append serial
          terminal_output --append serial
        '';
      };
      timeout = 1;
    };
  };

  fileSystems = mkMerge [
    (mkOrder 1 (flip map config.boot.loader.grub.mirroredBoots
      (arg:
      assert arg.path != "/boot"; # We should never see the default path
      assert length arg.devices == 1; # There should always be a 1 - 1 map between paths and devices
      {
        mountPoint = arg.path;
        device = "${head arg.devices}-part2";
        fsType = "vfat";
        options = [
          "defaults"
          "noatime"
        ];
        neededForBoot = true;
      })
    ))
    (mkOrder 1 [
      {
        mountPoint = "/tmp";
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "defaults"
          "noatime"
        ];
        neededForBoot = true;
      }
    ])
  ];

  system.extraDependencies = with pkgs; [
    grub_bios-i386 grub_efi-x86_64 grub_efi-i386
  ];
}

{ config, lib, ... }:
with lib;
{
  imports = [ ./fs-root.nix ];
  boot.initrd.supportedFilesystems = [ "xfs" ];
  fileSystems = mkMerge [
    (mkOrder 0 [
      {
        mountPoint = "/";
        fsType = "xfs";
        device = "/dev/disk/by-uuid/${config.rootUUID}";
        options = [
          "defaults"
          "noatime"
        ];
        neededForBoot = true;
      }
    ])
    (mkOrder 2 [
      {
        mountPoint = "/etc/nixos";
        fsType = "none";
        device = "/conf/nixos";
        neededForBoot = true;
        options = [
          "defaults"
          "bind"
        ];
      }
      {
        mountPoint = "/home";
        fsType = "none";
        device = "/state/home";
        neededForBoot = true;
        options = [
          "defaults"
          "bind"
        ];
      }
      {
        mountPoint = "/root";
        fsType = "none";
        device = "/state/home/root";
        neededForBoot = true;
        options = [
          "defaults"
          "bind"
        ];
      }
      {
        mountPoint = "/var/lib";
        fsType = "none";
        device = "/state/lib";
        neededForBoot = true;
        options = [
          "defaults"
          "bind"
        ];
      }
      {
        mountPoint = "/var/db";
        fsType = "none";
        device = "/state/lib";
        neededForBoot = true;
        options = [
          "defaults"
          "bind"
        ];
      }
    ])
  ];
}

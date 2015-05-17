{ lib, ... }:
with lib;
{
  imports = [ ./fs-root.nix ];
  boot = {
    initrd.supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
      forceImportAll = false;
    };
  };
  fileSystems = mkMerge [
    (mkOrder 0 [
      {
        mountPoint = "/";
        fsType = "zfs";
        device = "root";
        neededForBoot = true;
      }
    ])
    (mkOrder 1 [
      {
        mountPoint = "/conf";
        fsType = "zfs";
        device = "root/conf";
        neededForBoot = true;
      }
      {
        mountPoint = "/nix";
        fsType = "zfs";
        device = "root/nix";
        neededForBoot = true;
      }
      {
        mountPoint = "/state";
        fsType = "zfs";
        device = "root/state";
        neededForBoot = true;
      }
      {
        mountPoint = "/tmp";
        fsType = "zfs";
        device = "root/tmp";
        neededForBoot = true;
      }
      {
        mountPoint = "/var/log";
        fsType = "zfs";
        device = "root/log";
        neededForBoot = true;
      }
    ])
    (mkOrder 2 [
      {
        mountPoint = "/etc/nixos";
        fsType = "none";
        device = "/conf/nixos";
        neededForBoot = true;
        options = "defaults,bind";
      }
      {
        mountPoint = "/home";
        fsType = "none";
        device = "/state/home";
        neededForBoot = true;
        options = "defaults,bind";
      }
      {
        mountPoint = "/root";
        fsType = "none";
        device = "/state/home/root";
        neededForBoot = true;
        options = "defaults,bind";
      }
      {
        mountPoint = "/var/lib";
        fsType = "none";
        device = "/state/lib";
        neededForBoot = true;
        options = "defaults,bind";
      }
      {
        mountPoint = "/var/db";
        fsType = "none";
        device = "/state/lib";
        neededForBoot = true;
        options = "defaults,bind";
      }
    ])
  ];
}

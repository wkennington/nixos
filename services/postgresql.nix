{ config, lib, pkgs, ... }:
with lib;
{
  fileSystems = [
    {
      mountPoint = "/var/db/postgresql";
      fsType = "zfs";
      device = "root/state/postgresql";
      neededForBoot = true;
    }
  ];
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql93;
  };
}

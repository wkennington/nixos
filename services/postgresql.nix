{ config, lib, pkgs, ... }:
with lib;
{
  fileSystems."/var/db/postgresql" = {
    fsType = "zfs";
    device = "root/state/postgresql";
    neededForBoot = true;
  };
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql93;
  };
}

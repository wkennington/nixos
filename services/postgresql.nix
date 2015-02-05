{ config, lib, pkgs, ... }:
with lib;
{
  fileSystems."/var/db/postgresql" = mkIf (config.fileSystems."/".fsType == "zfs") {
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

{ lib, pkgs, ... }:
with lib;
{
  options = {
    cephPackage = mkOption {
      default = pkgs.ceph-dev;
    };
  };
}

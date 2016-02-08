{ lib, pkgs, ... }:
with lib;
{
  options = {
    cephPackage = mkOption { };
  };
}

{ lib, ... }:
with lib;
{
  options = {
    cephPackage = mkOption { };
  };
}

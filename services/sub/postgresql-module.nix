{ lib, ... }:
with lib;
{
  options = {
    postgresqlPackage = mkOption { };
  };
}

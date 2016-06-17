{ config, lib, ... }:

with lib;
{
  require = [
    ./sub/postgresql-module.nix
  ];
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = config.postgresqlPackage;
  };
  users.extraUsers.postgres.useDefaultShell = true;
}

{ config, lib, pkgs, ... }:
with lib;
{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql94;
  };
  users.extraUsers.postgres.useDefaultShell = true;
}

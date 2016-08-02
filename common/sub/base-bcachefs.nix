{ config, lib, pkgs, ... }:
{
  boot.kernelPackages = lib.mkOverride 0 pkgs.linuxPackages_bcache;

  environment.systemPackages = [
    pkgs.bcache-tools_dev
  ];
}
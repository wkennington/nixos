{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.glusterfs
  ];
}

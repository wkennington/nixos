{ config, lib, pkgs, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
in
{
  environment.systemPackages = [
    pkgs.glusterfs
  ];
  networking.firewall.extraCommands = ''
    ip46tables -A INPUT -p tcp --dport 24007 -s ${calculated.myInternalIp4Net} -j ACCEPT
  '';
}

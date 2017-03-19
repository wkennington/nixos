{ config, lib, pkgs, ... }:
let
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
in
{
  environment.systemPackages = [
    pkgs.glusterfs
  ];
  networking.firewall.extraCommands = ''
    iptables -A INPUT -p tcp --dport 24007 -s ${calculated.myInternalIp4Net} -j ACCEPT
    iptables -A INPUT -p tcp --dport 49152 -s ${calculated.myInternalIp4Net} -j ACCEPT
  '';
}

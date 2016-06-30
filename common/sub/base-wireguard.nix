{ config, pkgs, ... }:
{
  boot.extraModulePackages = [
    config.boot.kernelPackages.wireguard
  ];
  environment.systemPackages = [
    pkgs.wireguard
  ];
  networking.firewall.extraCommands = ''
    ip46tables -A INPUT -p udp --dport 655 -j ACCEPT
    ip46tables -A OUTPUT -p udp --dport 655 -j ACCEPT
  '';
}

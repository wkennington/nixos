{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.ipfs-cluster
  ];
  services.ipfs-cluster.enable = true;
  networking.firewall.extraCommands = ''
    # Allow communicating with the local ipfs daemon
    ip46tables -A OUTPUT -m owner --uid-owner ipfs-cluster -o lo -p tcp --dport 5001 -j ACCEPT
  '';
}

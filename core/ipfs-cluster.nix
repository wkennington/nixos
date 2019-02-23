{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.ipfs-cluster
  ];
  services.ipfs-cluster.enable = true;
  networking.firewall.extraCommands = ''
    # Allow communicating with the local ipfs daemon
    ip46tables -A OUTPUT -m owner --uid-owner ipfs-cluster -o lo -p tcp --dport 5001 -j ACCEPT

    # Allow ipfs-cluster to communicate with other ipfs-clusters
    ip46tables -A INPUT -p tcp --dport 9096 -j ACCEPT
    ip46tables -A OUTPUT -m owner --uid-owner ipfs-cluster -p tcp --dport 9096 -j ACCEPT
  '';
}

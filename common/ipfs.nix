{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ipfs
  ];

  networking.firewall = {
    allowedTCPPorts = [ 4001 ];
    allowedUDPPorts = [ 4001 ];

    extraCommands = ''
      # Allow all other processes to acccess the gateway
      ip46tables -A OUTPUT -o lo -p tcp --dport 8001 -j ACCEPT
    '';
  };

  services.ipfs = {
    enable = true;
  };
}

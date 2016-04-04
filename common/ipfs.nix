{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ipfs
  ];

  networking.firewall = {
    allowedTCPPorts = [ 4001 ];
    allowedUDPPorts = [ 4001 ];
  };

  services.ipfs = {
    enable = true;
  };
}

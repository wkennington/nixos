{ config, lib, pkgs, ... }:
let
  inherit (lib)
    concatLists
    flip
    optionals;

  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  addresses = optionals (calculated.myPublicIp4 != null) [
    "/ip4/${calculated.myPublicIp4}"
  ] ++ optionals (calculated.myPublicIp6 != null) [
    "/ip6/${calculated.myPublicIp6}"
  ];

  addresses' =
    if addresses != [] then
      addresses
    else
      [ "/ip4/0.0.0.0" "/ip6/::" ];

  swarm = concatLists (flip map addresses' (n: [
    "${n}/tcp/4001"
  ] ++ optionals (config.services.ipfs.utp) [
    "${n}/udp/4001/utp"
  ]));
in
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
    extraAttrs =  {
      Addresses = {
        Swarm = swarm;
        API = "/ip4/127.0.0.1/tcp/5001";
        Gateway = "/ip4/127.0.0.1/tcp/8001";
      };
    };
  };

  systemd.services.ipfs = {
    serviceConfig = {
      MemoryMax = "4G";
      CPUQuota = "100%";
    };
  };
}

{ config, lib, pkgs, ... }:
let
  vars = (import ../customization/vars.nix { inherit lib; });
  tincConfig = (import ../customization/tinc.nix { inherit lib; });
  id = vars.vpn.idMap.${config.networking.hostName};
in
with lib;
{
  environment.systemPackages = [ pkgs.tinc_pre ];
  fileSystems = [
    {
      mountPoint = "/etc/tinc";
      fsType = "none";
      device = "/conf/tinc";
      neededForBoot = true;
      options = "defaults,bind";
    }
  ];
  networking = {
    interfaces."tinc.vpn".ip4 = [
      { address = "${vars.vpn.subnet}${toString id}"; prefixLength = 24; }
    ];
    firewall = {
      allowedTCPPorts = [ 655 ];
      allowedUDPPorts = [ 655 ];
      extraCommands = ''
        ip46tables -A OUTPUT -m owner --uid-owner tinc.vpn -p udp --dport 655 -j ACCEPT
        ip46tables -A OUTPUT -m owner --uid-owner tinc.vpn -p tcp --dport 655 -j ACCEPT
      '';
    };
  };
  services.tinc.networks.vpn = {
    package = pkgs.tinc_pre;
    name = config.networking.hostName;
    extraConfig = ''
      StrictSubnets yes
      TunnelServer yes
      DirectOnly yes
    '' + flip concatMapStrings tincConfig.dedicated (n: ''
      ConnectTo ${n}
    '');
    hosts = tincConfig.hosts;
  };
}

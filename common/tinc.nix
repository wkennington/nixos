{ config, lib, pkgs, ... }:

with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  tincConfig = (import ../customization/tinc.nix { inherit lib; });
  calculated = (import ./sub/calculated.nix { inherit config lib; });
  id = vars.vpn.idMap.${config.networking.hostName};

  remoteNets = if calculated.iAmRemote then vars.netMaps else
    flip filterAttrs vars.netMaps
      (n: { priv4, ... }: priv4 == calculated.myNetMap.priv4);
  extraRoutes = mapAttrsToList (n: { priv4, ... }: "${priv4}0.0/16") remoteNets;
in
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
    localCommands = flip concatMapStrings extraRoutes (n: ''
      ip route del "${n}" dev tinc.vpn >/dev/null 2>&1 || true
      ip route add "${n}" dev tinc.vpn
    '');
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

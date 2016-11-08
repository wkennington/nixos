{ config, lib, pkgs, ... }:

with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  tincConfig = (import ../customization/tinc.nix { inherit lib; });
  calculated = (import ./sub/calculated.nix { inherit config lib; });
in
{
  imports = [
    ./sub/vpn.nix
  ];

  myNatIfs = [
    "${vars.domain}.vpn"
  ];

  environment.systemPackages = [
  environment.systemPackages = [
    config.services.tinc.networks.vpn.package
  ];

  fileSystems = [
    {
      mountPoint = "/etc/tinc";
      fsType = "none";
      device = "/conf/tinc";
      neededForBoot = true;
      options = [
        "defaults"
        "bind"
      ];
    }
  ];

  networking = {
    firewall = {
      allowedTCPPorts = [ 655 ];
      allowedUDPPorts = [ 655 ];
      extraCommands = ''
        ip46tables -A OUTPUT -m owner --uid-owner ${vars.domain}.vpn -p udp --dport 655 -j ACCEPT
        ip46tables -A OUTPUT -m owner --uid-owner ${vars.domain}.vpn -p tcp --dport 655 -j ACCEPT
      '';
    };
  };

  services.tinc.networks."${vars.domain}.vpn" = {
    package = pkgs.tinc_1_1;
    name = config.networking.hostName;
    extraConfig = ''
      StrictSubnets yes
      TunnelServer yes
      DirectOnly yes
      AutoConnect yes
    '' + flip concatMapStrings tincConfig.dedicated (n: ''
      ConnectTo ${n}
    '');
    hosts = mkMerge [
      tincConfig.hosts
      (flip mapAttrs tincConfig.hosts (host: _:
        let
          remote = calculated.isRemote host;
          netMap = vars.netMaps.${calculated.dc host};
          hostMap = netMap.internalMachineMap.${host};
          gateway = any (n: n == host) netMap.gateways;
        in ''
          Subnet = ${vars.vpn.subnet}${toString vars.vpn.idMap.${host}}/32
        '' + optionalString (!remote) (
          flip concatMapStrings (hostMap.vlans) (vlan: ''
            Subnet = ${calculated.internalIp4 host vlan}/32
          '') + optionalString gateway ''
            Subnet = ${netMap.priv4}0.0/16
          ''
        )
      ))
    ];
  };
}

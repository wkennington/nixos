{ config, lib, utils, ... }:
with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  devices = flip map vars.gateway.natIfs
    (n: "sys-subsystem-net-devices-${utils.escapeSystemdPath n}.device");
in
{
  imports = [
    ../../common/sub/base-dnsmasq.nix
  ];
  networking.firewall.extraCommands =
    flip concatMapStrings vars.gateway.natIfs (n: ''
      ip46tables -A INPUT -i ${n} -p udp --dport domain -j ACCEPT
      ip46tables -A INPUT -i ${n} -p tcp --dport domain -j ACCEPT
    '');
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    extraConfig = flip concatMapStrings vars.gateway.natIfs (n: ''
      interface=${n}
      no-dhcp-interface=${n}
    '');
  };
  systemd.services.dnsmasq = {
    after = devices;
    bindsTo = devices;
  };
}

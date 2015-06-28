{ config, lib, utils, ... }:
with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  internalVlanMap = listToAttrs (flip map (calculated.myNetData.vlans ++ [ "lan" ]) (v:
    nameValuePair v vars.internalVlanMap.${v}
  ));
  systemdDevices = flip map (attrNames internalVlanMap)
    (n: "sys-subsystem-net-devices-${utils.escapeSystemdPath n}.device");

  net = calculated.myNetMap;
in
{
  networking.firewall.extraCommands =
    flip concatMapStrings (attrNames internalVlanMap) (n: ''
      iptables -w -A INPUT -i ${n} -p udp --dport 67 -j ACCEPT
    '');

  services.dhcpd = {
    enable = true;
    interfaces = attrNames internalVlanMap;
    extraConfig = ''
      max-lease-time 86400;
      default-lease-time 86400;
      option subnet-mask 255.255.255.0;
    '' + concatStrings (flip mapAttrsToList internalVlanMap (vlan: vid:
      let
        subnet = "${net.priv4}${toString vid}";
        nameservers = concatStringsSep ", " (dnsIp4 vlan);
        dhcpLower = "${subnet}.${toString vars.gateway.dhcpRange.lower}";
        dhcpUpper = "${subnet}.${toString vars.gateway.dhcpRange.upper}";
      in ''
        subnet ${subnet}.0 netmask 255.255.255.0 {
          option broadcast-address ${subnet}.255;
          option routers ${subnet}.1;
          option domain-name-servers ${nameservers};
          option domain-name "${calculated.myDomain}";
          range ${dhcpLower} ${dhcpUpper};
        }
      ''
    ));
  };

  systemd.services.dhcpd = {
    after = systemdDevices;
    bindsTo = systemdDevices;
  };
}

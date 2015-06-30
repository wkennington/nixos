{ config, lib, pkgs, utils, ... }:
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

  primary = config.networking.hostName == head net.dhcpServers;
  peer = if primary then head (tail net.dhcpServers) else head net.dhcpServers;
in
{
  assertions = [ {
    assertion = length net.dhcpServers < 3;
    message = "You must not have more than 2 dhcp servers.";
  } ];

  networking.firewall.extraCommands = ''
    ip46tables -A INPUT -i tlan -p tcp --dport 647 -j ACCEPT
    ip46tables -A OUTPUT -o tlan -m owner --uid-owner dhcpd -p tcp --dport 647 -j ACCEPT
  '' + flip concatMapStrings (attrNames internalVlanMap) (n: ''
      iptables -w -A INPUT -i ${n} -p udp --dport 67 -j ACCEPT
    '');

  services.dhcpd = {
    enable = true;
    interfaces = attrNames internalVlanMap;
    configFile = pkgs.writeText "dhcpd.conf" (''
      authoritative;
      ddns-updates off;
      log-facility local1; # see dhcpd.nix

      max-lease-time 86400;
      default-lease-time 86400;

      option subnet-mask 255.255.255.0;
    '' + optionalString (peer != null) ''
      failover peer failover {
        ${if primary then "primary" else "secondary"};
        address ${calculated.internalIp4 config.networking.hostName "tlan"};
        port 647;
        peer address ${calculated.internalIp4 peer "tlan"};
        peer port 647;
        max-response-delay 30;
        max-unacked-updates 20;
        mclt 3600;
        ${optionalString primary "split 128;"}
        load balance max seconds 3;
      }
    '' + concatStrings (flip mapAttrsToList internalVlanMap (vlan: vid:
      let
        subnet = "${net.priv4}${toString vid}";
        nameservers = concatStringsSep ", " (calculated.dnsIp4 vlan);
        dhcpLower = "${subnet}.${toString vars.gateway.dhcpRange.lower}";
        dhcpUpper = "${subnet}.${toString vars.gateway.dhcpRange.upper}";
      in ''
        subnet ${subnet}.0 netmask 255.255.255.0 {
          option broadcast-address ${subnet}.255;
          option routers ${subnet}.1;
          option domain-name-servers ${nameservers};
          option domain-name "${calculated.myDomain}";
          pool {
            ${optionalString (peer != null) "failover peer \"failover\";"}
            range ${dhcpLower} ${dhcpUpper};
          }
        }
      ''
    )));
  };

  systemd.services.dhcpd = {
    after = systemdDevices;
    bindsTo = systemdDevices;
    partOf = systemdDevices;
  };
}

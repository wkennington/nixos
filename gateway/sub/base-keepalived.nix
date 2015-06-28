{ config, lib, pkgs, ... }:
with lib;
let
  vars = (import ../../customization/vars.nix { inherit lib; });
  calculated = (import ../../common/sub/calculated.nix { inherit config lib; });

  internalVlanMap = listToAttrs (flip map (calculated.myNetData.vlans ++ [ "lan" ]) (v:
    nameValuePair v vars.internalVlanMap.${v}
  ));

  net = calculated.myNetMap;

  configFile = pkgs.writeText "keepalived.conf" ''
    global_defs {
      router_id ${config.networking.hostName}
    }

    vrrp_sync_group GATEWAY {
      group {
        WAN
    ${concatStringsSep "\n" (flip mapAttrsToList internalVlanMap (vlan: _: "    ${toUpper vlan}"))}
      }
    }
    
    vrrp_instance WAN {
      state BACKUP
      nopreempt
      preempt_delay 5
      interface tlan
      track_interface {
        WAN
      }
      virtual_router_id 254
      priority ${toString calculated.myNetData.id}
      advert_int 1
      authentication {
        auth_type PASS
        auth_pass doesntmatter
      }
      virtual_ipaddress {
        ${calculated.myNetMap.pub4}${toString calculated.myNetMap.pub4MachineMap.outbound} dev wan
      }
    }

    ${concatStrings (flip mapAttrsToList internalVlanMap (vlan: vid: ''
      vrrp_instance ${toUpper vlan} {
        state BACKUP
        nopreempt
        preempt_delay 5
        interface tlan
        track_interface {
          ${vlan}
        }
        virtual_router_id ${toString (vid + 1)}
        priority ${toString calculated.myNetData.id}
        advert_int 1
        authentication {
          auth_type PASS
          auth_pass doesntmatter
        }
        virtual_ipaddress {
          ${calculated.gatewayIp4 config.networking.hostName vlan} dev ${vlan}
        }
      }
    ''))}
  '';
in
{
  networking.firewall.extraCommands = ''
    # Allow other keepalived's to talk to this one
    iptables -I INPUT -i tlan -d 224.0.0.0/8 -j ACCEPT
    ip46tables -I INPUT -i tlan -p vrrp -j ACCEPT
  '';

  systemd.services.keepalived = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "sys-subsystem-net-devices-tlan.device" ];
    bindsTo = [ "sys-subsystem-net-devices-tlan.device" ];
    partOf = [ "sys-subsystem-net-devices-tlan.device" ];
    serviceConfig.ExecStart = "${pkgs.keepalived}/bin/keepalived -P --release-vips -D -n -f ${configFile}";
  };
}

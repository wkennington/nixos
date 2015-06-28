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
    ${concatStringsSep "\n" (flip mapAttrsToList internalVlanMap (vlan: _: "    ${toUpper vlan}"))}
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
  systemd.services.keepalived = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig.ExecStart = "${pkgs.keepalived}/bin/keepalived -PDnf ${configFile}";
  };
}

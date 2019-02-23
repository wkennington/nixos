{ config, lib, pkgs, ... }:
with lib;
let

  cfg = config.services.keepalived;

  vrrpInstance = name: config: ''
    vrrp_instance ${name} {
      state ${config.state}
      ${optionalString (!config.preempt) "nopreempt"}
      ${optionalString (config.preemptDelay != null) "preempt_delay ${toString config.preemptDelay}"}
      interface ${config.interface}
      ${optionalString (config.trackInterfaces != [ ]) ''
        track_interface {
          ${concatMapStrings (i: "    ${i}\n") config.trackInterfaces}
        }
      ''}
      virtual_router_id ${toString config.virtualRouterId}
      priority ${toString config.priority}
      advert_int ${toString config.advertInt}
      garp_master_delay ${toString config.garpMasterDelay}
      authentication {
        auth_type ${config.authType}
        auth_pass ${config.authPass}
      }
      ${optionalString (config.virtualIpAddresses != [ ]) ''
        virtual_ipaddress {
          ${flip concatMapStrings config.virtualIpAddresses (i:
            "    ${i.ip}" +
            (optionalString (i.broadcast != null) " brd ${i.broadcast}") +
            (optionalString (i.device != null) " dev ${i.device}") +
            (optionalString (i.scope != null) " scope ${i.scope}") +
            (optionalString (i.label != null) " label ${i.label}") +
            "\n"
          )}
        }
      ''}
    }
  '';

  notifyScript = lines: pkgs.writeScript "notify-script" ''
    #! ${pkgs.stdenv.shell}
    set -e
    set -o pipefail

    ${lines}
  '';

  vrrpSyncGroup = name: config: ''
    vrrp_sync_group ${name} {
      group {
        ${concatMapStrings (n: "    ${n}\n") config.group}
      }
      ${optionalString (config.notifyMaster != null) "notify_master \"${notifyScript config.notifyMaster}\""}
      ${optionalString (config.notifyBackup != null) "notify_backup \"${notifyScript config.notifyBackup}\""}
      ${optionalString (config.notifyFault != null) "notify_fault \"${notifyScript config.notifyFault}\""}
      ${optionalString (config.notifyStop != null) "notify_stop \"${notifyScript config.notifyStop}\""}
    }
  '';

  configFile = pkgs.writeText "keepalived.conf" ''
    global_defs {
      router_id ${cfg.routerId}
      script_user root
      enable_script_security
    }
    ${concatStrings (mapAttrsToList vrrpSyncGroup cfg.syncGroups)}
    ${concatStrings (mapAttrsToList vrrpInstance cfg.instances)}
  '';

  interfaces = (attrNames (fold (n: m: m // { ${n.interface} = null; }) {} (attrValues cfg.instances)));

  ips = concatLists (flip mapAttrsToList cfg.instances (n: d:
    map (v: { inherit (v) ip; device = if v.device == null then d.interface else v.device; }) d.virtualIpAddresses));
in
{
  options = {

    services.keepalived = {
      
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the keepalive daemon.
        '';
      };

      routerId = mkOption {
        type = types.str;
        default = config.networking.hostName;
        description = ''
          The label of the node used when sending email.
        '';
      };

      syncGroups = mkOption {
        type = types.attrsOf types.optionSet;
        default = { };
        description = ''
          Defines a vrrp_sync_group block.
        '';
        options = {

          group = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = ''
              Add an entry for each vrrp_instance you want to be a part of the sync group.
            '';
          };

          notifyMaster = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = ''
              Add a notify_master script to run when this node becomes the master.
            '';
          };

          notifyBackup = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = ''
              Add a notify_backup script to run when this node becomes the backup.
            '';
          };

          notifyFault = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = ''
              Add a notify_fault script to run when a node faults.
            '';
          };

          notifyStop = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = ''
              Add a notify_stop script to run when a node faults.
            '';
          };

        };
      };

      instances = mkOption {
        type = types.attrsOf types.optionSet;
        default = [ ];
        description = ''
          Defines a vrrp_instance block.
        '';
        options = {

          state = mkOption {
            type = types.addCheck types.str (n: elem n [ "MASTER" "BACKUP" ]);
            default = "BACKUP";
            description = ''
              The state the node should start in.
            '';
          };

          preempt = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether the state of a node should be preemptible for master elections.
            '';
          };

          preemptDelay = mkOption {
            type = types.nullOr (types.addCheck types.int (n: n > 0));
            default = null;
            description = ''
              The number of seconds until we decide to preempt the master election when no other nodes are found.
              null means not to set the value and use the default.
            '';
          };

          interface = mkOption {
            type = types.str;
            description = ''
              The interface used for sending vrrp packets as well as the default interface assigned to ips.
            '';
          };

          trackInterfaces = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = ''
              Other interfaces to track to determine the FAULT state of the instance.
              Any interfaces in the virtual assignment should be here.
            '';
          };

          virtualRouterId = mkOption {
            type = types.addCheck types.int (n: n > 0 && n < 256);
            description = ''
              A unique identifier for this instance that is consistent among routers
            '';
          };

          priority = mkOption {
            type = types.addCheck types.int (n: n > 0 && n < 256);
            description = ''
              The priority of this node having this instance assigned.
              This should be unique between nodes also using this instance.
            '';
          };

          advertInt = mkOption {
            type = types.addCheck types.int (n: n > 0);
            default = 1;
            description = ''
              The interval of time between probes for instance advertisement.
            '';
          };

          garpMasterDelay = mkOption {
            type = types.addCheck types.int (n: n > 0);
            default = 10;
            description = ''
              The delay for gratuitous ARP after transition to MASTER.
            '';
          };

          authType = mkOption {
            type = types.addCheck types.str (n: elem n [ "PASS" "AH" ]);
            default = "PASS";
            description = ''
              The type of authorization to perform when receiving a vrrp packet.
            '';
          };

          authPass = mkOption {
            type = types.str;
            description = ''
              The password to send for vrrp communication authentication.
              NOTE: This is world readable currently as nix has no way to support secrets.
              Please avoid using this for security, use it more as a sanity check.
              It is advisable to create a secure network for communication.
            '';
          };

          virtualIpAddresses = mkOption {
            type = types.listOf types.optionSet;
            default = [ ];
            options = {

              ip = mkOption {
                type = types.str;
                description = ''
                  The ip address and prefixLength to be assigned to the interface.
                  The format should look like "<ip>/<prefix>"
                '';
              };

              broadcast = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  The broadcast address to assign.
                '';
              };

              device = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  The device to which the ip should be assigned
                '';
              };

              scope = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  The scope of the ip address, mostly used for ipv6.
                '';
              };

              label = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  The label to apply to the ip address.
                '';
              };

            };
          };

        };
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra lines to add to the configuration file.
        '';
      };

    };

  };

  config = mkIf cfg.enable {

    assertions = concatLists (flip mapAttrsToList cfg.syncGroups (name: g:
      flip map g.group (i: {
        assertion = cfg.instances ? "${i}";
        message = "VRRP Sync Group ${name} contains a non-existant instance ${i}";
      })
    ));

    networking.firewall.extraCommands = flip concatMapStrings interfaces (n: ''
      # Allow other keepalived's to talk to this one
      iptables -A nixos-fw -i ${n} -d 224.0.0.0/8 -j nixos-fw-accept
      ip46tables -A nixos-fw -i ${n} -p vrrp -j nixos-fw-accept
    '');

    systemd.services.keepalived = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      path = [ pkgs.iproute ];

      preStart = concatStrings (flip mapAttrsToList cfg.syncGroups (_: config: ''
        ${optionalString (config.notifyBackup != null) (notifyScript config.notifyBackup)}
      ''));

      postStop = flip concatMapStrings ips ({ ip, device }: ''
        if ip addr show dev "${device}" | grep -q "${ip}"; then
          echo "Have to remove an extra ip from ${device}: ${ip}"
          if ! ip addr del "${ip}" dev "${device}"; then
            echo "Failed to remove ${ip} from ${device}"
          fi
        fi
      '');

      serviceConfig.ExecStart = "${pkgs.keepalived}/bin/keepalived -P --release-vips -D -n -f ${configFile}";
    };

  };
}

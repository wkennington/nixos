{ config, lib, pkgs, ... }:

with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ./sub/calculated.nix { inherit config lib; });
  domain = "consul.${vars.domain}";

  isServer = flip any calculated.myConsul.serverIps
    (ip: ip == calculated.myInternalIp4);
  isAclMaster = vars.consulAclDc == calculated.myDc && isServer;

  certName = "${config.networking.hostName}.${calculated.myDc}.${domain}";
in
{
  myDns.forwardZones."${domain}" = [
    {
      server = "127.0.0.1";
      port = 8600;
    }
  ];

  environment.etc."consul.d/systemd-failed.json".text = builtins.toJSON {
    check = {
      id = "systemd-failed";
      name = "Systemd Failed Units";
      script = ''
        OUT="$(${config.systemd.package}/bin/systemctl --failed)"
        echo "$OUT"
        if echo "$OUT" | ${pkgs.gnugrep}/bin/grep -q '0 loaded units listed'; then
          exit 0
        fi
        exit 1 # Warning (We don't want services to fail because of this)
      '';
      interval = "60s";
    };
  };

  environment.etc."consul.d/systemd-starting.json".text = builtins.toJSON {
    check = {
      id = "systemd-starting";
      name = "Systemd Starting Units";
      script = ''
        touch /dev/shm/systemd-starting-jobs
        PREVIOUS="$(cat /dev/shm/systemd-starting-jobs)"

        OUT="$(${config.systemd.package}/bin/systemctl list-jobs)"
        PARSED="$(echo "$OUT" | tail -n +2 | head -n -2)"
        echo "$PARSED" | tee /dev/shm/systemd-starting-jobs

        if [ -z "$PARSED" ] || [ "$PARSED" != "$PREVIOUS" ]; then
          exit 0
        fi
        exit 1 # Warning (We don't want services to fail because of this)
      '';
      interval = "120s";
    };
  };

  networking.firewall = {
    extraCommands = ''
      # Allow consul to communicate with other consuls
      ip46tables -A INPUT -p tcp --dport 8300:8302 -j ACCEPT
      ip46tables -A INPUT -p udp --dport 8301:8302 -j ACCEPT
      ip46tables -A OUTPUT -m owner --uid-owner consul -p tcp --dport 8300:8302 -j ACCEPT
      ip46tables -A OUTPUT -m owner --uid-owner consul -p udp --dport 8301:8302 -j ACCEPT

      # Allow consul to interact with itself
      ip46tables -A OUTPUT -m owner --uid-owner consul -o lo -p udp --dport 8600 -j ACCEPT
      ip46tables -A OUTPUT -m owner --uid-owner consul -o lo -p tcp --dport 8600 -j ACCEPT
      ip46tables -A OUTPUT -m owner --uid-owner consul -o lo -p tcp --dport 8400 -j ACCEPT
    '' + optionalString (config.services.dnsmasq.enable) ''
      # Allow dnsmasq to query consul
      ip46tables -A OUTPUT -m owner --uid-owner dnsmasq -o lo -p udp --dport 8600 -j ACCEPT
      ip46tables -A OUTPUT -m owner --uid-owner dnsmasq -o lo -p tcp --dport 8600 -j ACCEPT
    '' + optionalString (config.services.unbound.enable) ''
      # Allow unbound to query consul
      ip46tables -A OUTPUT -m owner --uid-owner unbound -o lo -p udp --dport 8600 -j ACCEPT
      ip46tables -A OUTPUT -m owner --uid-owner unbound -o lo -p tcp --dport 8600 -j ACCEPT
    '';
  };
  services.consul = {
    enable = true;
    extraConfig = {
      acl_datacenter = vars.consulAclDc;
      acl_default_policy = "deny";
      acl_down_policy = "deny";
      acl_token = "anonymous";
      advertise_addr = calculated.myInternalIp4;
      bind_addr = calculated.myInternalIp4;
      ca_file = "/conf/consul/ca.crt";
      cert_file = "/conf/consul/${certName}.crt";
      datacenter = calculated.myDc;
      disable_remote_exec = true;
      domain = "${domain}";
      key_file = "/conf/consul/${certName}.key";
      server = isServer;
      retry_join = flip filter calculated.myConsul.serverIps
        (ip: ip != calculated.myInternalIp4);
      verify_incoming = true;
      verify_outgoing = true;
      verify_server_hostname = true;
    } // (if ! isServer then { } else {
      bootstrap_expect = length calculated.myConsul.serverIps;
    });
    dropPrivileges = true;
    extraConfigFiles =  [ ]
      ++ optional isAclMaster "/conf/consul/acl-master-1.json";
    forceIpv4 = true;
  };

  systemd.services.consul = {
    path = [ pkgs.acl ];
    preStart = ''
      setfacl -m u:consul:r /conf/consul/${certName}.key
    '' + optionalString isAclMaster ''
      setfacl -m u:consul:r /conf/consul/acl-master-1.json
    '';
  };
}

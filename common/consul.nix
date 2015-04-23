{ config, lib, ... }:

with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ./sub/calculated.nix { inherit config lib; });
  domain = "consul.${vars.domain}";

  isServer = flip any calculated.myConsul.serverIps
    (ip: ip == calculated.myInternalIp4);
  isAclMaster = vars.consulAclDc == calculated.myDc && isServer;
in
{
  imports = [
    ./sub/base-dnsmasq.nix
  ];
  services.dnsmasq.extraConfig = ''
    server=/${domain}/127.0.0.1#8600
  '';
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
      
      # Allow dnsmasq to query consul
      ip46tables -A OUTPUT -m owner --uid-owner dnsmasq -o lo -p udp --dport 8600 -j ACCEPT
      ip46tables -A OUTPUT -m owner --uid-owner dnsmasq -o lo -p tcp --dport 8600 -j ACCEPT
    '';
  };
  services.consul = {
    enable = true;
    joinNodes = flip filter calculated.myConsul.serverIps
      (ip: ip != calculated.myInternalIp4);
    extraConfig = {
      acl_datacenter = vars.consulAclDc;
      acl_default_policy = "deny";
      acl_down_policy = "deny";
      acl_token = "anonymous";
      advertise_addr = calculated.myInternalIp4;
      bind_addr = calculated.myInternalIp4;
      ca_file = "/conf/consul/ca.crt";
      cert_file = "/conf/consul/me.crt";
      datacenter = calculated.myDc;
      disable_remote_exec = true;
      domain = "${domain}";
      key_file = "/conf/consul/me.key";
      server = isServer;
      verify_incoming = true;
      verify_outgoing = true;
    } // (if ! isServer then { } else {
      bootstrap_expect = length calculated.myConsul.serverIps;
    });
    dropPrivileges = true;
    extraConfigFiles = optional isAclMaster "/conf/consul/acl-master-1.json";
    forceIpv4 = true;
  };
}

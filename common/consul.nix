{ config, lib, ... }:
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ./sub/calculated.nix { inherit config lib; });
  domain = "consul.${vars.domain}";
in
with lib;
{
  imports = [
    ./sub/base-dnsmasq.nix
  ];
  services.dnsmasq.extraConfig = ''
    server=/${domain}/127.0.0.1#8600
  '';
  networking.firewall = {
    allowedTCPPorts = [ 8300 8301 8302 ];
    allowedUDPPorts = [ 8301 8302 ];
    extraCommands = ''
      ip46tables -A OUTPUT -m owner --uid-owner consul -o lo -p udp --dport 8600 -j ACCEPT
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
      acl_default_token = "anonymous";
      advertise_addr = calculated.myInternalIp4;
      bind_addr = calculated.myInternalIp4;
      bootstrap_expect = 3;
      ca_file = "/conf/consul/ca.crt";
      cert_file = "/conf/consul/me.crt";
      datacenter = calculated.myDc;
      disable_remote_exec = true;
      domain = "${domain}";
      key_file = "/conf/consul/me.key";
      server = flip any calculated.myConsul.serverIps
        (ip: ip == calculated.myInternalIp4);
      verify_incoming = true;
      verify_outgoing = true;
    };
    dropPrivileges = true;
    extraConfigFiles = [
      "/conf/consul/encrypt-1.json"
      "/conf/consul/acl-master-1.json"
    ];
    forceIpv4 = true;
  };
}

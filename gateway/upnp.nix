{ config, lib, ... }:
let
  calculated = (import ../../common/sub/calculated.nix { inherit config lib; });
in
{
  networking.firewall.extraCommands = lib.flip lib.concatMapStrings config.myNatIfs (i: ''
    # Allow traffic to the daemon
    ip46tables -A INPUT -i ${i} -p udp --dport 1900 -j ACCEPT
    ip46tables -A INPUT -i ${i} -p tcp --dport 1901 -j ACCEPT
    ip46tables -A INPUT -i ${i} -p udp --dport 5351 -j ACCEPT

  '') + ''
    # Add upnp tables if they don't exist
    if ! iptables -L 2>&1 | grep -q 'upnp-forward'; then
      ip46tables -N upnp-forward
      ip46tables -A upnp-forward -j RETURN
    fi
    if ! iptables -t nat -L 2>&1 | grep -q 'upnp-nat'; then
      ip46tables -t nat -N upnp-nat
      ip46tables -t nat -A upnp-nat -j RETURN
    fi

    # Add the mappings from the other chains
    ip46tables -A FORWARD -j upnp-forward
    ip46tables -t nat -A PREROUTING -j upnp-nat
  '';

  services.miniupnpd = {
    enable = true;
    externalInterface = "wan";
    internalIPs = config.myNatIfs;
    natpmp = true;
    upnp = true;
    appendConfig = ''
      http_port=1901

      upnp_forward_chain=upnp-forward
      upnp_nat_chain=upnp-nat

      secure_mode=yes

      system_uptime=yes

      lease_file=/var/lib/miniupnpd/leases

      uuid=797e683b-e968-4e21-af2a-56b53f8e06e7

      allow 40000-50000 ${calculated.myNetMap.priv4}0.0/16 40000-50000
      deny 0-65535 0.0.0.0/0 0-65535
    '';
  };

  systemd.services.miniupnpd.preStart = ''
    mkdir -p /var/lib/miniupnpd
    touch /var/lib/miniupnpd/leases
  '';
}

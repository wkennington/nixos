{ lib, ... }:

with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  # Make sure this is only used for wireguard and nothing else
  port = "655";
in
{
  imports = [
    ./sub/vpn.nix
  ];
  
  networking.wgs."${vars.domain}.vpn".configFile = "/etc/wg.${vars.domain}.conf";
  
  networking.firewall.extraCommands = ''
    ip46tables -A INPUT -p udp --dport ${port} -j ACCEPT
    ip46tables -A OUTPUT -p udp --dport ${port} -j ACCEPT
  '';
}

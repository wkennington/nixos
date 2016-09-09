{ ... }:
{
  networking.firewall.extraCommands = ''
    # Allow input to the sync port
    ip46tables -A INPUT -p tcp --dport 22000 -j ACCEPT
    ip46tables -A INPUT -p udp --dport 21027 -j ACCEPT

    # Allow local syncthings to access each other
    ip46tables -A OUTPUT -m owner --uid-owner syncthing -p tcp --dport 22000 -j ACCEPT
    ip46tables -A OUTPUT -m owner --uid-owner syncthing -p udp --dport 21027 -j ACCEPT

    # Allow privileged users to access syncthing's webui
    ip46tables -A OUTPUT -m owner --gid-owner wheel -o lo -p tcp --dport 8384 -j ACCEPT
  '';
  services.syncthing.enable = true;
}

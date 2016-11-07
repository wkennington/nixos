{ config, lib, pkgs, ... }:

with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  wgConfig = (import ../customization/wireguard.nix { });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  # Make sure this is only used for wireguard and nothing else
  port = 655;

  # Files needed to build the configuration
  secretDir = "/conf/wireguard";
  keyFile = "${secretDir}/${vars.domain}.key";
  pskFile = "${secretDir}/${vars.domain}.psk";

  confFileIn = pkgs.writeText "wg.conf.in" (''
    [Interface]
    PrivateKey = @KEY@
    PresharedKey = @PSK@
    ListenPort = ${toString port}
  '' + concatStrings (flip mapAttrsToList wgConfig.hosts (host: { publicKey, endpoint ? null }: ''
    
    [Peer]
    PublicKey = ${publicKey}
    AllowedIPs = ${calculated.vpnIp4 host}/32
    AllowedIPs = ${calculated.vpnIp6 host}/128
  '' + optionalString (endpoint != null) ''
    Endpoint = ${endpoint}
  '')));

  wgBuilder = pkgs.writeScript "wg.${vars.domain}.conf-builder" ''
    #! ${pkgs.stdenv.shell} -e

    cleanup() {
      rm -f "$TMP"
      trap - EXIT
      exit 0
    }
    trap cleanup EXIT ERR INT QUIT PIPE TERM
    TMP="$(mktemp -p "/dev/shm")"
    chmod 0600 "$TMP"
    cat "${confFileIn}" >"$TMP"

    if ! test -e "${keyFile}" || ! wg pubkey <"${keyFile}" >/dev/null 2>&1; then
      exit 2
    fi
    export KEY="$(cat "${keyFile}")"
    awk -i inplace '
      {
        gsub(/@KEY@/, ENVIRON["KEY"]);
        print;
      }
    ' "$TMP"

    if test -e "/conf/wireguard/${vars.domain}.psk"; then
      export PSK="$(cat "${pskFile}")"
      awk -i inplace '
        {
          gsub(/@PSK@/, ENVIRON["PSK"]);
          print;
        }
      ' "$TMP"
    else
      sed -i '/@PSK@/d' "$TMP"
    fi

    mv "$TMP" "/etc/wg.${vars.domain}.conf"
  '';
in
{
  imports = [
    ./sub/vpn.nix
  ];
  
  networking.wgs."${vars.domain}.vpn".configFile = "/etc/wg.${vars.domain}.conf";
  
  networking.firewall.extraCommands = ''
    ip46tables -A INPUT -p udp --dport ${toString port} -j ACCEPT
    ip46tables -A OUTPUT -p udp --dport ${toString port} -j ACCEPT
  '';

  systemd.services."build-wg.${vars.domain}.conf" = {
    serviceConfig = {
      Type = "oneshot";
      Restart = "no";
      RemainAfterExit = true;
      ExecStart = wgBuilder;
      ExecReload = wgBuilder;
    };

    unitConfig = {
      PropagatesReloadTo = "network-dev-${vars.domain}.vpn.service";
    };

    restartTriggers = [
      confFileIn
    ];
    reloadIfChanged = true;

    requiredBy = [
      "network-dev-${vars.domain}.vpn.service"
    ];
    before = [
      "network-dev-${vars.domain}.vpn.service"
    ];

    path = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnused
      pkgs.wireguard
    ];
  };
}

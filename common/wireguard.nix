{ config, lib, pkgs, ... }:

with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  wgConfig = (import ../customization/wireguard.nix { });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  # Make sure this is only used for wireguard and nothing else
  port = 656;

  # Files needed to build the configuration
  secretDir = "/conf/wireguard";
  keyFile = "${secretDir}/${vars.domain}.key";
  pskFile = "${secretDir}/${vars.domain}.psk";

  confFileIn = pkgs.writeText "wg.conf.in" (''
    [Interface]
    PrivateKey = @KEY@
    PresharedKey = @PSK@
    ListenPort = ${toString port}
  '' + concatStrings (flip mapAttrsToList wgConfig.hosts (host: { publicKey, endpoint ? null }: let
    netMap = vars.netMaps."${calculated.dc host}";
    remote = calculated.isRemote host;
    gateway = !remote && any (n: n == host) netMap.gateways;
  in ''
    
    [Peer]
    PublicKey = ${publicKey}
    AllowedIPs = ${calculated.vpnIp4 host}/32
    AllowedIPs = ${calculated.vpnIp6 host}/128
  '' + optionalString gateway ''
    AllowedIPs = ${netMap.priv4}0.0/16
  '' + optionalString ((calculated.iAmRemote || calculated.iAmGateway) && gateway) ''
    PersistentKeepalive = 20
  '' + optionalString (endpoint != null) ''
    Endpoint = ${endpoint}
  '')));

  confFile = "/dev/shm/wg/${vars.domain}.conf";

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

    mkdir -p "$(dirname "${confFile}")"
    chown root:root "$(dirname "${confFile}")"
    chmod 0700 "$(dirname "${confFile}")"
    mv "$TMP" "${confFile}"
  '';
in
{
  imports = [
    ./sub/vpn.nix
  ];
  
  networking.wgs."${vars.domain}.vpn".configFile = confFile;
  
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

    restartTriggers = [
      confFileIn
    ];

    requiredBy = [
      "wg-config-${vars.domain}.vpn.service"
    ];
    before = [
      "wg-config-${vars.domain}.vpn.service"
    ];

    path = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnused
      pkgs.wireguard
    ];
  };
}

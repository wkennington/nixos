{ config, lib, pkgs, ... }:

with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  wgConfig = (import ../customization/wireguard.nix { });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });

  # Make sure this is only used for wireguard and nothing else
  ports = {
    "${vars.domain}" = 656;
    "gw.${vars.domain}" = 657;
  };
  port = name: ports."${name}";

  # Files needed to build the configuration
  secretDir = "/conf/wireguard";
  keyFile = name: "${secretDir}/${name}.key";
  pskFile = name: "${secretDir}/${vars.domain}.psk";

  confFileIn = name: let
    name' = splitString "." name;
    iAmGateway = "gw" == head name';
  in pkgs.writeText "wg.${name}.conf.in" (''
    [Interface]
    PrivateKey = @KEY@
    PresharedKey = @PSK@
    ListenPort = ${toString (port name)}
  '' + concatStrings (flip mapAttrsToList wgConfig.hosts (host: { publicKey, endpoint ? null }: let
    host' = splitString "." host;
    hostIsGateway = "gw" == head host';
    netMap = vars.netMaps."${head (tail host')}";
    sendKeepalive = hostIsGateway && (calculated.iAmRemote ||
      (iAmGateway && ! calculated.myNetMap ? pub4)
    );
  in ''
    
    [Peer]
    PublicKey = ${publicKey}
  '' + optionalString (!hostIsGateway) ''
    AllowedIPs = ${calculated.vpnIp4 host}/32
    AllowedIPs = ${calculated.vpnIp6 host}/128
  '' + optionalString hostIsGateway ''
    AllowedIPs = ${netMap.priv4}0.0/16
  '' + optionalString sendKeepalive ''
    PersistentKeepalive = 20
  '' + optionalString (endpoint != null) ''
    Endpoint = ${endpoint}
  '')));

  confFile = name: "/dev/shm/wg/${name}.conf";

  wgBuilder = name: pkgs.writeScript "wg.${name}.conf-builder" ''
    #! ${pkgs.stdenv.shell} -e

    cleanup() {
      rm -f "$TMP"
      trap - EXIT
      exit 0
    }
    trap cleanup EXIT ERR INT QUIT PIPE TERM
    TMP="$(mktemp -p "/dev/shm")"
    chmod 0600 "$TMP"
    cat "${confFileIn name}" >"$TMP"

    if ! test -e "${keyFile name}" || ! wg pubkey <"${keyFile name}" >/dev/null 2>&1; then
      exit 2
    fi
    export KEY="$(cat "${keyFile name}")"
    awk -i inplace '
      {
        gsub(/@KEY@/, ENVIRON["KEY"]);
        print;
      }
    ' "$TMP"

    if test -e "${pskFile name}"; then
      export PSK="$(cat "${pskFile name}")"
      awk -i inplace '
        {
          gsub(/@PSK@/, ENVIRON["PSK"]);
          print;
        }
      ' "$TMP"
    else
      sed -i '/@PSK@/d' "$TMP"
    fi

    mkdir -p "$(dirname "${confFile name}")"
    chown root:root "$(dirname "${confFile name}")"
    chmod 0700 "$(dirname "${confFile name}")"
    mv "$TMP" "${confFile name}"
  '';

  interfaceConfig = name: nameValuePair "${name}.vpn" {
    port = port name;
    configFile = confFile name;
  };

  confService = name: nameValuePair "build-wg.${name}" {
    serviceConfig = {
      Type = "oneshot";
      Restart = "no";
      RemainAfterExit = true;
      ExecStart = wgBuilder name;
      ExecReload = wgBuilder name;
    };

    restartTriggers = [
      (confFileIn name)
    ];

    requiredBy = [
      "wg-config-${name}.vpn.service"
    ];
    before = [
      "wg-config-${name}.vpn.service"
    ];

    path = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnused
      pkgs.wireguard
    ];
  };
in
{
  imports = [
    ./sub/vpn.nix
  ];

  myNatIfs = mkIf (calculated.iAmGateway) [
    "gw.${vars.domain}.vpn"
  ];

  networking.interfaces = mkIf calculated.iAmGateway {
    "gw.${vars.domain}.vpn" = { };
  };

  networking.wgs = listToAttrs ([
    (interfaceConfig vars.domain)
  ] ++ optionals calculated.iAmGateway [
    (interfaceConfig "gw.${vars.domain}")
  ]);

  networking.firewall.extraCommands = flip concatMapStrings (attrValues ports) (port: ''
    ip46tables -A INPUT -p udp --dport ${toString port} -j ACCEPT
    ip46tables -A OUTPUT -p udp --dport ${toString port} -j ACCEPT
  '');

  systemd.services = listToAttrs ([
    (confService vars.domain)
  ] ++ optionals calculated.iAmGateway [
    (confService "gw.${vars.domain}")
  ]);
}

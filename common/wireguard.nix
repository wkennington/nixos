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

  haveGatewayInterface = calculated.iAmRemote || calculated.iAmGateway;

  confFileIn = name: let
    isGateway = host: "gw" == head (splitString "." host);
    hosts = flip filterAttrs wgConfig.hosts (host: { ... }:
      if host == config.networking.hostName || host == "gw.${calculated.myDc}" then
        false
      else if isGateway name then
        calculated.isRemote host || isGateway host
      else
        ! isGateway host
    );
  in pkgs.writeText "wg.${name}.conf.in" (''
    [Interface]
    PrivateKey = @KEY@
    PresharedKey = @PSK@
    ListenPort = ${toString (port name)}
  '' + concatStrings (flip mapAttrsToList hosts (host: { publicKey, endpoint ? null }: let
    netMap = vars.netMaps."${elemAt (splitString "." host) 1}";
    sendKeepalive = endpoint' != null && isGateway host && (calculated.iAmRemote ||
      !(calculated.myNetMap ? pub4)
    );
    vlans = vars.netMaps."${calculated.dc host}".internalMachineMap."${host}".vlans;
    vlans' = listToAttrs (map (vlan: nameValuePair (vlan) (true)) vlans);
    matchingVlans = filter (vlan: vlans' ? "${vlan}") calculated.myNetData.vlans;
    matchingVlan = if calculated.iAmRemote || matchingVlans == [ ] then head vlans else head matchingVlans;
    endpoint' =
      if endpoint != null then
        endpoint
      else if ! isGateway name then
        if calculated.isRemote host then
          "${vars.vpn.remote4}${toString vars.vpn.idMap."${host}"}:${toString (port name)}"
        else
          "${calculated.internalIp4 host matchingVlan}:${toString (port name)}"
      else
        null;
  in ''
    
    [Peer]
    PublicKey = ${publicKey}
  '' + optionalString (!isGateway name) ''
    AllowedIPs = ${calculated.vpnIp4 host}/32
    AllowedIPs = ${calculated.vpnIp6 host}/128
  '' + optionalString (isGateway name && !isGateway host) ''
    AllowedIPs = ${calculated.vpnGwIp4 host}/32
    AllowedIPs = ${calculated.vpnGwIp6 host}/128
  '' + optionalString (isGateway name && isGateway host) ''
    AllowedIPs = ${netMap.priv4}0.0/16
  '' + optionalString sendKeepalive ''
    PersistentKeepalive = 20
  '' + optionalString (endpoint' != null) ''
    Endpoint = ${endpoint'}
  '')));

  confFile = name: "/dev/shm/wg/${name}.conf";

  wgBuilder = name: pkgs.writeScript "wg.${name}.conf-builder" ''
    #! ${pkgs.stdenv.shell} -e

    cleanup() {
      ret=$?
      rm -f "$TMP"
      trap - EXIT
      exit $ret
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

  remoteNets =
    if calculated.iAmRemote then
      vars.netMaps
    else
      flip filterAttrs vars.netMaps
        (n: { priv4, ... }: priv4 != calculated.myNetMap.priv4);

  haveMultipleGateways = !calculated.iAmRemote && length calculated.myNetMap.gateways >= 2;

  extraRoutes = mapAttrsToList (n: { priv4, ... }: "${priv4}0.0/16") remoteNets;

  myId = vars.vpn.idMap.${config.networking.hostName};
in
{
  myNatIfs = mkIf calculated.iAmGateway [
    "gw.${vars.domain}.vpn"
  ];

  networking = {
    interfaces = mkMerge [
      ({
        "${vars.domain}.vpn" = {
          ip4 = optionals (vars.vpn ? subnet4) [
            { address = "${vars.vpn.subnet4}${toString myId}"; prefixLength = 24; }
          ];
          ip6 = optionals (vars.vpn ? subnet6) [
            { address = "${vars.vpn.subnet6}${toString myId}"; prefixLength = 64; }
          ];
        };
      })
      (mkIf haveGatewayInterface {
        "gw.${vars.domain}.vpn" = if ! calculated.iAmRemote then { } else {
          ip4 = optionals (vars.vpn ? remote4) [
            { address = "${vars.vpn.remote4}${toString myId}"; prefixLength = 24; }
          ];
          ip6 = optionals (vars.vpn ? remote6) [
            { address = "${vars.vpn.remote6}${toString myId}"; prefixLength = 64; }
          ];
        };
      })
    ];
  };

  networking.wgs = listToAttrs ([
    (interfaceConfig vars.domain)
  ] ++ optionals haveGatewayInterface [
    (interfaceConfig "gw.${vars.domain}")
  ]);

  networking.firewall.extraCommands = flip concatMapStrings (attrValues ports) (port: ''
    ip46tables -A INPUT -p udp --dport ${toString port} -j ACCEPT
    ip46tables -A OUTPUT -p udp --dport ${toString port} -j ACCEPT
  '');

  services.keepalived.syncGroups.gateway = mkIf haveMultipleGateways {
    notifyMaster = flip concatMapStrings extraRoutes (n: ''
      ip route del "${n}" || true
      ip route add "${n}" dev "gw.${vars.domain}.vpn" src "${calculated.myInternalIp4}"
    '') + ''
      ip route del "${vars.vpn.remote4}0/24" || true
      ip route add "${vars.vpn.remote4}0/24" dev "gw.${vars.domain}.vpn" \
        src "${calculated.myInternalIp4}"
    '';
    notifyBackup = flip concatMapStrings extraRoutes (n: ''
      ip route del "${n}" || true
      ip route add "${n}" via "${calculated.myGatewayIp4}" \
        src "${calculated.myInternalIp4}"
    '') + ''
      ip route del "${vars.vpn.remote4}0/24" || true
      ip route add "${vars.vpn.remote4}0/24" via "${calculated.myGatewayIp4}" \
        src "${calculated.myInternalIp4}"
    '';
    notifyFault = flip concatMapStrings extraRoutes (n: ''
      ip route del "${n}" || true
      ip route add "${n}" via "${calculated.myGatewayIp4}"
    '') + ''
      ip route del "${vars.vpn.remote4}0/24" || true
      ip route add "${vars.vpn.remote4}0/24" via "${calculated.myGatewayIp4}" \
        src "${calculated.myInternalIp4}"
    '';
  };

  systemd.services = mkMerge [
    (listToAttrs ([
      (confService vars.domain)
    ] ++ optionals haveGatewayInterface [
      (confService "gw.${vars.domain}")
    ]))
    (mkIf (haveGatewayInterface && !haveMultipleGateways) {
      "network-link-up-gw.${vars.domain}.vpn" = {
        postStart = flip concatMapStrings extraRoutes (n: ''
          ip route add "${n}" dev "gw.${vars.domain}.vpn" \
            ${optionalString calculated.iAmGateway "src ${calculated.myInternalIp4}"}
        '');
      };
    })
    (mkIf (calculated.iAmGateway && !haveMultipleGateways) {
      "network-link-up-gw.${vars.domain}.vpn" = let
        dependency = "network-addresses-${head calculated.myNetData.vlans}.service";
      in {
        requires = [ dependency ];
        after = [ dependency ];
        postStart = ''
          ip route add "${vars.vpn.remote4}0/24" dev "gw.${vars.domain}.vpn" \
            src "${calculated.myInternalIp4}"
        '';
      };
    })
  ];
}

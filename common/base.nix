{ config, lib, pkgs, ... }:
with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
in
{
  imports = [
    ./sub/base-firewall.nix
    ./sub/base-dnsmasq.nix
    ./sub/base-minimal.nix
    ./sub/base-ntpd.nix
  ];
  boot = {
    kernelPackages = mkDefault pkgs.linuxPackages_latest;
    extraModprobeConfig = ''
      options kvm-amd nested=1
      options kvm-intel nested=1
    '';
    kernel.sysctl = {
      "net.ipv6.conf.all.use_tempaddr" = 2;
      "net.ipv6.conf.default.use_tempaddr" = 2;
    };
  };
  environment.systemPackages = with pkgs; [
    acpi
    atop
    dnstop
    fish
    git
    gptfdisk
    htop
    iftop
    iotop
    iperf
    ipset
    iptables
    mtr
    nftables
    nmap
    config.programs.ssh.package
    openssl
    psmisc
    smartmontools
    sysstat
    tcpdump
    tmux
    vim
    wget
  ];
  networking.domain = calculated.myDomain;
  nix = {
    nrBuildUsers = config.nix.maxJobs * 10;
    buildCores = config.nix.maxJobs;
    useChroot = true;
    binaryCaches = [ "https://cache.nixos.org" "https://hydra.nixos.org" ];
  };
  programs.bash = {
    enableCompletion = true;
    promptInit = "PS1=\"[\\u@\\h:\\w]\\\\$ \"\n";
  };
  services = {
    journald.extraConfig = "SystemMaxUse=50M";
    logind.extraConfig = "HandleLidSwitch=sleep";
  };
  users = {
    mutableUsers = false;
    extraUsers = {
      root = {
        hashedPassword = null;
        passwordFile = "/conf/pw/root";
      };
    } // flip mapAttrs vars.userInfo (user:
      { uid, description, canRoot, loginMachines, canShareData }:
      let
        canLogin = any (n: n == config.networking.hostName) loginMachines;
      in {
        inherit uid description;
        createHome = canLogin;
        home = "/home/${user}";
        extraGroups = [ ]
          ++ optional canRoot "wheel"
          ++ optional canShareData "share";
        useDefaultShell = canLogin;
        passwordFile = if canLogin then "/conf/pw/${user}" else null;
      });
    extraGroups = {
      share.gid = 1001;
    };
  };
  time.timeZone = mkDefault calculated.myTimeZone;
}

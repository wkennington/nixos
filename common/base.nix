{ config, lib, pkgs, ... }:
with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
  nixVersion = head (tail (splitString "-" pkgs.nix.name));
  doesNixSupportSigning = versionAtLeast nixVersion "1.9";
in
{
  imports = [
    # ./sub/base-dnsmasq.nix  # We are using unbound now
    ./sub/base-firewall.nix
    ./sub/base-hosts.nix
    ./sub/base-networking.nix
    ./sub/base-ntpd.nix
    ./sub/base-unbound.nix
    ./sub/base-wireguard.nix
  ];
  require = [
    ./sub/base-dns-module.nix
    ./sub/base-fs-module.nix
    ./sub/base-if-module.nix
    ./sub/base-keepalived-module.nix
  ];
  boot = {
    kernelPackages = if lib.versionAtLeast (pkgs.linuxPackages_latest.kernel.version) "4.0"
      then pkgs.linuxPackages_latest else pkgs.linuxPackages_testing;
    extraModprobeConfig = ''
      options kvm-amd nested=1
      options kvm-intel nested=1
    '';
    kernel.sysctl = {
      "net.ipv4.ip_nonlocal_bind" = 1;
      "net.ipv6.conf.all.use_tempaddr" = 2;
      "net.ipv6.conf.default.use_tempaddr" = 2;
    };
  };
  environment.systemPackages = with pkgs; [
    acpi
    dnsutils
    edac-utils
    efibootmgr
    fish
    git
    gnupg
    gptfdisk
    hdparm
    htop
    iftop
    iotop
    iperf
    ipmitool
    ipset
    iptables
    ldns
    lm-sensors
    mtr
    nftables
    nmap
    config.programs.ssh.package
    openssl
    psmisc
    rsync
    smartmontools
    sysstat
    tcpdump
    tmux
    vim
  ];
  hardware.cpu = {
    intel.updateMicrocode = true;
    amd.updateMicrocode = true;
  };
  networking.domain = calculated.myDomain;
  nix = {
    package = if doesNixSupportSigning then pkgs.nix else pkgs.nixUnstable;
    nrBuildUsers = config.nix.maxJobs * 10;
    buildCores = config.nix.maxJobs;
    allowedUsers = [ "@wheel" ];
  };
  programs = {
    bash = {
      enableCompletion = true;
      promptInit = "PS1=\"[\\u@\\h:\\w]\\\\$ \"\n";
    };
    ssh.package = pkgs.openssh;
  };
  services = {
    journald.extraConfig = "SystemMaxUse=1G";
    logind.extraConfig = "HandleLidSwitch=suspend";
  };
  system.extraDependencies = with pkgs; [
    # Extra compilers take a long time to compile so keep them always
    go
    #rustc

    # We always want to keep small trust roots
    cacert dnssec-root
  ] ++ stdenv.bootstrappedPackages; # Make sure we never need the bootstrap
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

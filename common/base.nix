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
    ./sub/base-firewall.nix
    ./sub/base-dnsmasq.nix
    ./sub/base-minimal.nix
    ./sub/base-networking.nix
    ./sub/base-ntpd.nix
  ];
  boot = {
    kernelPackages = if lib.versionAtLeast (pkgs.linuxPackages_latest.kernel.version) "4.0"
      then pkgs.linuxPackages_latest else pkgs.linuxPackages_testing;
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
    dnsutils
    edac-utils
    fish
    git
    gptfdisk
    hdparm
    htop
    iftop
    iotop
    iperf
    ipmitool
    ipset
    iptables
    lm_sensors
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
  hardware.cpu = {
    intel.updateMicrocode = true;
    amd.updateMicrocode = true;
  };
  networking.domain = calculated.myDomain;
  nix = {
    package = if doesNixSupportSigning then pkgs.nix else pkgs.nixUnstable;
    nrBuildUsers = config.nix.maxJobs * 10;
    buildCores = config.nix.maxJobs;
    useChroot = true;
    binaryCaches = [ "https://cache.nixos.org" "https://hydra.nixos.org" ];
    binaryCachePublicKeys = [ "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=" ];
    requireSignedBinaryCaches = true;
  };
  programs = {
    bash = {
      enableCompletion = true;
      promptInit = "PS1=\"[\\u@\\h:\\w]\\\\$ \"\n";
    };
    ssh.package = pkgs.openssh;
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

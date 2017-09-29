{ config, lib, pkgs, ... }:
with lib;
let
  vars = (import ../customization/vars.nix { inherit lib; });
  calculated = (import ../common/sub/calculated.nix { inherit config lib; });
in
{
  imports = [
    # ./sub/base-dnsmasq.nix  # We are using unbound now
    ./sub/base-firewall.nix
    ./sub/base-hosts.nix
    ./sub/base-networking.nix
    ./sub/base-ntpd.nix
    ./sub/base-ssh.nix
    ./sub/base-unbound.nix
  ];
  require = [
    ./sub/base-dns-module.nix
    ./sub/base-fs-module.nix
    ./sub/base-if-module.nix
    ./sub/base-keepalived-module.nix
  ];
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    zfs.useDev = true;  # We want encryption
    supportedFilesystems = [ "ext4" "xfs" "btrfs" "zfs" "vfat" "ntfs" ];
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
  environment.etc."ssl/openssl.cnf".source = "${pkgs.openssl}/etc/ssl/openssl.cnf";
  environment.systemPackages = with pkgs; [
    acme-client
    acpi
    aria2
    bind_tools
    borgbackup
    curl
    dmidecode
    edac-utils
    efibootmgr
    efivar
    fio
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
    jq
    ldns
    lftp
    lm-sensors
    mcelog
    mtr
    nftables
    nmap
    config.programs.ssh.package
    openssl
    pinentry
    powertop
    psmisc
    rsync
    smartmontools
    sysstat
    tcpdump
    time
    tmux
    vim
    unzip
  ];
  hardware.cpu = {
    intel.updateMicrocode = true;
    amd.updateMicrocode = true;
  };
  networking.domain = calculated.myDomain;
  networking.search = [ vars.domain ];
  nix = {
    buildCores = config.nix.maxJobs;
    allowedUsers = [ "@wheel" ];
  };
  programs = {
    bash = {
      enableCompletion = true;
      promptInit = "PS1=\"[\\u@\\h:\\w]\\\\$ \"\n";
    };
  };
  services = {
    journald.extraConfig = "SystemMaxUse=1G";
    logind.extraConfig = "HandleLidSwitch=suspend";
  };
  system.extraDependencies = with pkgs; [
    # We always want to keep small trust roots
    cacert
    root-nameservers
  ];
  systemd.extraConfig = ''
    DefaultCPUAccounting=on
    DefaultMemoryAccounting=on
    DefaultBlockIOAccounting=on
    DefaultTasksAccounting=on
  '';
  users = {
    mutableUsers = false;
    extraUsers = flip mapAttrs vars.userInfo (user:
      { uid, description, canRoot, loginMachines, canShareData, sshKeys }:
      let
        canLogin = if user == "root" then true else any (n: n == config.networking.hostName) loginMachines;
      in (if user == "root" then { } else {
        inherit uid description;
        createHome = canLogin;
        home = "/home/${user}";
        group = if canLogin then "users" else "nogroup";
        extraGroups = [ ]
          ++ optional canRoot "wheel"
          ++ optional canShareData "share";
        useDefaultShell = canLogin;
      }) // {
        hashedPassword = null;
        passwordFile = if canLogin then "/conf/pw/${user}" else null;
        openssh.authorizedKeys.keys = if canLogin then sshKeys else [ ];
      });
    extraGroups = {
      share.gid = 1001;
    };
  };
  time.timeZone = mkDefault calculated.myTimeZone;
}

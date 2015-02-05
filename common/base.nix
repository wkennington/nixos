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
    ./sub/base-ntpd.nix
  ];
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
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
  fonts.fontconfig.enable = false;
  networking.domain = calculated.myDomain;
  nix = {
    nrBuildUsers = config.nix.maxJobs * 10;
    buildCores = config.nix.maxJobs;
    useChroot = true;
    binaryCaches = [ "https://cache.nixos.org" "https://hydra.nixos.org" ];
  };
  programs = {
    bash = {
      enableCompletion = true;
      promptInit = "PS1=\"[\\u@\\h:\\w]\\\\$ \"\n";
    };
    ssh.startAgent = false;
  };
  security.sudo.enable = false;
  services = {
    nscd.enable = false;
    cron.enable = false;
    journald.extraConfig = "SystemMaxUse=50M";
    logind.extraConfig = "HandleLidSwitch=sleep";
  };
  users = {
    mutableUsers = false;
    extraUsers.root = {
      hashedPassword = null;
      passwordFile = "/conf/pw/root";
    };
  };
}

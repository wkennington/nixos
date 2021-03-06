{ config, pkgs, ... }:
{
  environment.etc."wpa_supplicant.conf" = {
    enable = true;
    mode = "0600";
    source = "/conf/wpa_supplicant.conf";
  };
  environment.systemPackages = with pkgs; [
    powertop
  ];
  networking.wireless = {
    enable = true;
    interfaces = [ "wifi" ];
  };
  services.xserver = {
    multitouch.enable = true;
    synaptics = {
      enable = true;
      tapButtons = false;
      twoFingerScroll = true;
      additionalOptions = ''
        Option "RTCornerButton" "2"
      '';
    };
  };
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="scsi_host", TEST=="link_power_management_policy", ATTR{link_power_management_policy}="min_power"
    ACTION=="add", SUBSYSTEM=="module", TEST=="parameters/power_save", ATTR{parameters/power_save}="1"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth*", RUN+="${pkgs.ethtool}/bin/ethtool -s $name wol d"
  '';
}

{ config, pkgs, ... }:
{
  environment.etc."wpa_supplicant.conf" = {
    enable = true;
    mode = "0600";
    source = "/etc/nixos/laptop/res/wpa_supplicant.conf";
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
}

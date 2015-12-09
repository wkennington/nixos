{ config, pkgs, ... }:
{
  environment.etc."wpa_supplicant.conf" = {
    enable = true;
    mode = "0600";
    source = "/conf/wpa_supplicant.conf";
  };
  networking.wireless = {
    enable = true;
    interfaces = [ "wifi" ];
  };
}

{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ mosh ];
  networking.firewall.allowedUDPPortRanges = [
    { from = 60000; to = 61000; }
  ];
  services.openssh = {
    enable = true;
    hostKeys = [
      { path = "/etc/ssh/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
      { path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; bits = 256; }
    ];
    forwardX11 = false;
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
    extraConfig = pkgs.lib.mkAfter ''
      AllowAgentForwarding yes
      AllowTcpForwarding no
      PrintMotd no
      UseDNS no

      Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
      KexAlgorithms curve25519-sha256@libssh.org
      MACs hmac-sha2-512-etm@openssh.com

      Match User root
        AllowTcpForwarding yes
    '';
  };
  users.extraUsers = {
    root.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCaML/Xk1bJe1wlvB5SVU3DM81FtcA/6QRsTfKavjroCPUeVL53tSUizIfUUhHE6yn/8wA+tkaCu3I4Cz5N1jeu6Wk/vKPSSGCqxAEufrLnk+ImueBx6zFKuaO5EnMKhcwoz62TEOYSssHas2n2diDFf6NIDyOKo20eZkKTU7tL8WOpLeUcLvxqKLpLP0T6z10dIkdS/vAStDJfemEz2Nk+4+jFapRyMoxf4E5Tmit8vVdZUQq0WDrwima7VTm1P733OfSkCSX6IlPpPRE6ZR2/ACiU6GJR/vmaIupMKupUP5iGs8+qv5igY+Ry1pD3VM2HuLJ+TUkXKlkaRvuWYEcmVNr+06b08z/GZBY/3DIyVgOD33A9DCyA+p+BJ/F8btFG51TaEUkJT78m+DTuNVcEzTOjTrK6mw1QwTI5RBPHVezTrEtQaNtN/d+v69X4SWu+5CW+P2IK8o3h8xvSemkgGH3n1bLl43zs9tI1Zpqb1YDR2cChbRqMwkPxizagFZ2/eaq96dLcjgGTXGXBFoRmaDr0Vt/m7nPgGXCu8l1uguYvDKUJHkpZXYo5QGWAGu4dZ/Zku/BQiCyLVSUHSlGtb7vfoUHc6sRLYAUg404Dh8jNNQ2xwatdOJmbHTzzcTSHi8rgg2MPDQGC9iKSTIOMR1yze14Zsr3Q9WIii2ha/w== prodigy"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCXp9ztqjMi1Nqd2DXrmNpH7MFW+PGDcpNloGR5Wq1ITnPIG/ntpbqKz2L1VW1HDYjaoqURiORz6/qem/UmiXmLSJX388L3q1ngSmTaOZ9g+49yrhbGMTHmsMKR7oFc8xbg60DPBuubTtm1pW4my0vTntVa1zmFMy5UFrV8KshH22wrxdIPm8dLf99jD58jqVxGjQuSeZh/1jBD16iduXqWi2ZkqtcCPjQGiMJ6wlRvgCzSCso/ZmDDY4pJHYLY+Ad6o6kcwdmA2Y5J+8RuOKkmuHXxgTW0gtGhvX+pum5X2NdeqwUugLk1gj7Of8UeGbSB9fQV9GbmlEohOaBxSSCYA9sc3gzW3nls2d7ORAHBqLUDKvOzK7sjb+AqVPnQdb9wjfi/OYEK+SSGF9a9i9C+eRTyPbHrBwVTvoOtFbfYh7KFchxrD9iAfONOLQzfTQWmY6HIKSadKZv1YS4j6o3aXKXp+P3opymY+OK2EwYS7C71kCMqQ3CPVTz5tnxbJm+aJJ34aWrDH1cZeTGemHW0JHPYIBDse0g32c/z7yUTsRFr5HF/PTlKgak96npPU8cDmPUQE+79ckzgGBsIPudZpzwsqtIlYamaivsE5Lp1cdDniJeEMC0T2F5FJ82/FRF8z98uboclxiUM19080YGRxKWqEL95i1eSWjYYyxIKqw== Keychain"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYksVeV279APcbu5ZH8lV5ZGlthPR8AOpYxUOKzddfAsFOYD5F96tKeD3iqsHmvCzPOUcH3Af20wyQC3tlW34bLxvhoJXxnp+U9Mwbc0mIlcdEQjWQvuPi12O3K/UIdS4EwIk7Yi6TIq53mDlFLVJEQMbmA2hiB5I2vmH0MBq/oi8/Dqs/EpiQJYyaHrZboJuClqOLAIw8Bv0U1GJVISssqq6RwenCwheMtZGEUp029hlwkL3BWRz6vFpnZltSgrh/h1QjRuw4LOM2ARoe+F6M2krGKShNx6yQ4mIevmgJ+pTVfO2MV+s2CpGO6jVH0ihNUJGZCDm9I1uLE05JPVgaUvbbqMkwa1oIOQLww+8LDQBJmzjAJs9fGNJn9G4kCh67CEEg3ZjS55fHoYxizve/ETXTvxWJqGOeSsjLAMtnlJlAmqE2/M0v86ylhojppbGjBiZAjiPuX+9LdEICCvHKft4ZLuu6jOZrytm6v9N6EC2JaGukjkkt3kfSAEDH6xYUM9JSsULUlzNJigHhBriMUixoRHIhYmN7pvu9sS29cLmUdc3/L85ARs5rOJfQpOZZ4BWioIN1PKD/YxmvX2kXFcfYdOsc4asXCmLclIF4WThkpJ8E8RcqvBruSBfVUkALOcBLx91SwemuHoVwTMOAl/He5BidC+I4a2+ofReQzw== legend"
    ];
  };
}

{ lib, ... }:
with lib;
rec {
  gateway = {
    dhcpRange = {
      lower = 200;
      upper = 254;
    };
  };

  internalVlanMap = {
    lan = 0; # Must Exist For Compatability
    mlan = 1; # Must Exist
    slan = 2; # Must Exist
    dlan = 3;
    ulan = 4;
    tlan = 5;
  };

  portMap = {
  };

  vpn = {
    # Assumes a prefix of /24
    subnet4 = "192.168.17.";
    subnet6 = "fdd5:7d0c:d804::";
    idMap = {
      prodigy = 2;
      atomic = 3;
      legend = 4;
      nevada = 5;
      newton = 8;
      page = 9;
      quest = 10;
      elite = 11;
      lotus = 12;
    };
  };

  domain = "wak.io";

  consulAclDc = "fmt-1";

  userInfo = {
    root = {
      uid = 0;
      description = "root";
      canRoot = true;
      loginMachines = [ ];  # This field is irrelevant since root can always login
      canShareData = false;
      sshKeys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCaML/Xk1bJe1wlvB5SVU3DM81FtcA/6QRsTfKavjroCPUeVL53tSUizIfUUhHE6yn/8wA+tkaCu3I4Cz5N1jeu6Wk/vKPSSGCqxAEufrLnk+ImueBx6zFKuaO5EnMKhcwoz62TEOYSssHas2n2diDFf6NIDyOKo20eZkKTU7tL8WOpLeUcLvxqKLpLP0T6z10dIkdS/vAStDJfemEz2Nk+4+jFapRyMoxf4E5Tmit8vVdZUQq0WDrwima7VTm1P733OfSkCSX6IlPpPRE6ZR2/ACiU6GJR/vmaIupMKupUP5iGs8+qv5igY+Ry1pD3VM2HuLJ+TUkXKlkaRvuWYEcmVNr+06b08z/GZBY/3DIyVgOD33A9DCyA+p+BJ/F8btFG51TaEUkJT78m+DTuNVcEzTOjTrK6mw1QwTI5RBPHVezTrEtQaNtN/d+v69X4SWu+5CW+P2IK8o3h8xvSemkgGH3n1bLl43zs9tI1Zpqb1YDR2cChbRqMwkPxizagFZ2/eaq96dLcjgGTXGXBFoRmaDr0Vt/m7nPgGXCu8l1uguYvDKUJHkpZXYo5QGWAGu4dZ/Zku/BQiCyLVSUHSlGtb7vfoUHc6sRLYAUg404Dh8jNNQ2xwatdOJmbHTzzcTSHi8rgg2MPDQGC9iKSTIOMR1yze14Zsr3Q9WIii2ha/w== prodigy"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCXp9ztqjMi1Nqd2DXrmNpH7MFW+PGDcpNloGR5Wq1ITnPIG/ntpbqKz2L1VW1HDYjaoqURiORz6/qem/UmiXmLSJX388L3q1ngSmTaOZ9g+49yrhbGMTHmsMKR7oFc8xbg60DPBuubTtm1pW4my0vTntVa1zmFMy5UFrV8KshH22wrxdIPm8dLf99jD58jqVxGjQuSeZh/1jBD16iduXqWi2ZkqtcCPjQGiMJ6wlRvgCzSCso/ZmDDY4pJHYLY+Ad6o6kcwdmA2Y5J+8RuOKkmuHXxgTW0gtGhvX+pum5X2NdeqwUugLk1gj7Of8UeGbSB9fQV9GbmlEohOaBxSSCYA9sc3gzW3nls2d7ORAHBqLUDKvOzK7sjb+AqVPnQdb9wjfi/OYEK+SSGF9a9i9C+eRTyPbHrBwVTvoOtFbfYh7KFchxrD9iAfONOLQzfTQWmY6HIKSadKZv1YS4j6o3aXKXp+P3opymY+OK2EwYS7C71kCMqQ3CPVTz5tnxbJm+aJJ34aWrDH1cZeTGemHW0JHPYIBDse0g32c/z7yUTsRFr5HF/PTlKgak96npPU8cDmPUQE+79ckzgGBsIPudZpzwsqtIlYamaivsE5Lp1cdDniJeEMC0T2F5FJ82/FRF8z98uboclxiUM19080YGRxKWqEL95i1eSWjYYyxIKqw== Keychain"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYksVeV279APcbu5ZH8lV5ZGlthPR8AOpYxUOKzddfAsFOYD5F96tKeD3iqsHmvCzPOUcH3Af20wyQC3tlW34bLxvhoJXxnp+U9Mwbc0mIlcdEQjWQvuPi12O3K/UIdS4EwIk7Yi6TIq53mDlFLVJEQMbmA2hiB5I2vmH0MBq/oi8/Dqs/EpiQJYyaHrZboJuClqOLAIw8Bv0U1GJVISssqq6RwenCwheMtZGEUp029hlwkL3BWRz6vFpnZltSgrh/h1QjRuw4LOM2ARoe+F6M2krGKShNx6yQ4mIevmgJ+pTVfO2MV+s2CpGO6jVH0ihNUJGZCDm9I1uLE05JPVgaUvbbqMkwa1oIOQLww+8LDQBJmzjAJs9fGNJn9G4kCh67CEEg3ZjS55fHoYxizve/ETXTvxWJqGOeSsjLAMtnlJlAmqE2/M0v86ylhojppbGjBiZAjiPuX+9LdEICCvHKft4ZLuu6jOZrytm6v9N6EC2JaGukjkkt3kfSAEDH6xYUM9JSsULUlzNJigHhBriMUixoRHIhYmN7pvu9sS29cLmUdc3/L85ARs5rOJfQpOZZ4BWioIN1PKD/YxmvX2kXFcfYdOsc4asXCmLclIF4WThkpJ8E8RcqvBruSBfVUkALOcBLx91SwemuHoVwTMOAl/He5BidC+I4a2+ofReQzw== legend"
      ];
    };
    william = {
      uid = 1000;
      description = "William A. Kennington III";
      canRoot = true;
      loginMachines = [ "legend" "prodigy" "lotus" ];
      canShareData = true;
      inherit (userInfo.root) sshKeys;
    };
    bill = {
      uid = 1001;
      description = "William A. Kennington Jr";
      canRoot = false;
      loginMachines = [ ];
      canShareData = true;
      sshKeys = [ ];
    };
    linda = {
      uid = 1002;
      description = "Linda D. Kennington";
      canRoot = false;
      loginMachines = [ ];
      canShareData = true;
      sshKeys = [ ];
    };
    ryan = {
      uid = 1003;
      description = "Ryan C. Kennington";
      canRoot = false;
      loginMachines = [ ];
      canShareData = true;
      sshKeys = [ ];
    };
    sumit = {
      uid = 1004;
      description = "Sumit R. Punjabi";
      canRoot = false;
      loginMachines = [ ];
      canShareData = true;
      sshKeys = [ ];
    };
  };

  remotes = [ "nixos" "prodigy" "lotus" ];

  pubDnsServers = [
    "8.8.8.8"
    "8.8.4.4"
  ];

  pubNtpServers = [
    { server = "0.pool.ntp.org"; weight = "1"; }
    { server = "1.pool.ntp.org"; weight = "1"; }
    { server = "2.pool.ntp.org"; weight = "1"; }
    { server = "3.pool.ntp.org"; weight = "1"; }
  ];

  # netMaps currently assumes /16 ipv4 and /60 ipv6 allocations
  # ip processing in nix is hard :/
  netMaps = {
    "abe-p" = {
      priv4 = "10.0.";
      priv6 = "fda4:941a:81b5:000";

      pubDnsServers = [
        "8.8.8.8"
        "8.8.4.4"
      ];

      pubNtpServers = [
        { server = "clock.nyc.he.net"; weight = "5"; }
        { server = "0.us.pool.ntp.org"; weight = "1"; }
        { server = "1.us.pool.ntp.org"; weight = "1"; }
        { server = "2.us.pool.ntp.org"; weight = "1"; }
      ];

      timeZone = "America/New_York";

      gateways = [
        "atomic"
      ];

      dhcpServers = [
        "atomic"
      ];

      dnsServers = [
        "atomic"
      ];

      ntpServers = [
        { server = "atomic"; weight = "1"; }
      ];

      consul = {
        servers = [ "atomic" ];
      };

      internalMachineMap = {
        atomic = {
          id = 30;
          vlans = [ "slan" "mlan" "dlan" "ulan" "tlan" ];
          bmcMac = "00:12:83:36:DC:00";
        };
        elite = {
          id = 31;
          vlans = [ "slan" "dlan" ];
          bmcMac = "00:12:83:36:DC:00";
        };
      };

      nasIds = [ 8 9 ];

      nases = [
        "elite"
      ];
    };

    "fmt-1" = {
      pub4 = "65.19.134.";
      pub4Gateway = "65.19.134.241";
      pub4PrefixLength = 28;

      pub6 = "2001:470:1:572::";
      pub6Gateway = "2001:470:1:572::1";
      pub6PrefixLength = 64;

      priv4 = "10.2.";
      priv6 = "fda4:941a:81b5:200";

      pubDnsServers = [
        "8.8.8.8"
        "8.8.4.4"
      ];

      pubNtpServers = [
        { server = "clock.fmt.he.net"; weight = "5"; }
        { server = "clock.sjc.he.net"; weight = "5"; }
        { server = "clepsydra.dec.com"; weight = "2"; }
        { server = "clock.via.net"; weight = "1"; }
        { server = "tock.gpsclock.com"; weight = "1"; }
      ];

      timeZone = "America/Los_Angeles";

      gateways = [
        "page"
        "quest"
      ];

      dhcpServers = [
        "page"
        "quest"
      ];

      dnsServers = [
        "newton"
        "page"
        "quest"
      ];

      ntpServers = [
        { server = "newton"; weight = "1"; }
        { server = "page"; weight = "1"; }
        { server = "quest"; weight = "1"; }
      ];

      ceph = {
        fsId = "82f46d16-7a12-436a-b18a-f612136c4062";
        mons = [ "newton" "page" "quest" ];
      };

      consul = {
        servers = [ "newton" "page" "quest" ];
      };

      pub6MachineMap = {
        outbound = 2;
        newton = 3;
        page = 4;
        quest = 5;
        lb1 = 6;
        lb2 = 7;
        lb3 = 8;
      };

      pub4MachineMap = {
        newton = 242;
        page = 243;
        quest = 244;
        lb1 = 245;
        lb2 = 246;
        lb3 = 247;
        outbound = 254;
      };

      loadBalancerMap = {
        lb1 = "newton";
        lb2 = "page";
        lb3 = "quest";
      };

      vrrpMap = {
        lan-4 = 1;
        lan-6 = 2;
        mlan-4 = 3;
        mlan-6 = 4;
        slan-4 = 5;
        slan-6 = 6;
        dlan-4 = 7;
        dlan-6 = 8;
        ulan-4 = 9;
        ulan-6 = 10;
        tlan-4 = 11;
        tlan-6 = 12;
        lb1-4 = 20;
        lb1-6 = 21;
        lb2-4 = 22;
        lb2-6 = 23;
        lb3-4 = 24;
        lb3-6 = 25;
        wan-4 = 254;
        wan-6 = 255;
      };

      internalMachineMap = {
        sw1g1 = {
          id = 11;
          vlans = [ "mlan" ];
          bmcMac = "00:12:83:36:DC:00";
        };
        sw10g1 = {
          id = 21;
          vlans = [ "mlan" ];
          bmcMac = "84:C7:27:80:2B:EB";
        };
        newton = {
          id = 31;
          vlans = [ "slan" "mlan" "tlan" ];
          bmcMac = "BC:5F:F4:FE:7C:E1";
        };
        page = {
          id = 32;
          vlans = [ "slan" "mlan" "tlan" ];
          bmcMac = "BC:5F:F4:FE:7D:6D";
        };
        quest = {
          id = 33;
          vlans = [ "slan" "mlan" "tlan" ];
          bmcMac = "BC:5F:F4:FE:7C:FF";
        };
        delta = {
          id = 34;
          vlans = [ "slan" ];
          bmcMac = "00:25:90:7C:A1:AE";
        };
        ferrari = {
          id = 35;
          vlans = [ "slan" ];
          bmcMac = "bc:5f:f4:c9:a0:70";
        };
        atlas = {
          id = 36;
          vlans = [ "slan" ];
          bmcMac = "0C:C4:7A:AE:6D:80";
        };
        nevada = {
          id = 37;
          vlans = [ "slan" ];
          bmcMac = "00:C0:A8:12:34:56";
        };
      };
    };

    "mtv-w" = {
      priv4 = "10.1.";
      pub6 = "2001:470:810a:000";
      priv6 = "fda4:941a:81b5:100";

      pubDnsServers = [
        "8.8.8.8"
        "8.8.4.4"
      ];

      pubNtpServers = [
        { server = "clock.fmt.he.net"; weight = "5"; }
        { server = "clock.sjc.he.net"; weight = "5"; }
        { server = "clepsydra.dec.com"; weight = "2"; }
        { server = "clock.via.net"; weight = "1"; }
        { server = "tock.gpsclock.com"; weight = "1"; }
      ];

      timeZone = "America/Los_Angeles";

      gateways = [
        "lazarus"
      ];

      dhcpServers = [
        "lazarus"
      ];

      dnsServers = [
        "lazarus"
      ];

      ntpServers = [
        { server = "lazarus"; weight = "1"; }
      ];

      # Cannot use 1 as this is reserved for the default gateway
      internalMachineMap = {
        lazarus = { id = 1; vlans = [ "slan" "mlan" "dlan" "ulan" "tlan" ]; };
        exodus = { id = 32; vlans = [ "slan" ]; };
        legend = { id = 33; vlans = [ "slan" ]; };
      };

    };
  };
}

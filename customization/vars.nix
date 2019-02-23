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
    remote4 = "192.168.18.";

    # Assumes a prefix of /64
    subnet6 = "fdd5:7d0c:d804::";
    remote6 = "fdd8:ce9d:52a5::";

    idMap = {
      #prodigy = 2;
      atomic = 3;
      legend = 4;
      nevada = 5;
      atlas = 6;
      ferrari = 7;
      newton = 8;
      page = 9;
      quest = 10;
      elite = 11;
      #lotus = 12;
      exodus = 13;
      delta = 14;
      lake = 15;
      jupiter = 16;
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
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTgCTxC4LUon2NLsLpbIfM68NHO2rGmnRKA+vqE7AXxQ00wryhPJPngQl6c/nwHbm8v9Oi7IPAyuPXAFWoulO6PIxni1RH4k3o040vNIs32mzQY8234GMACYBevaT6nh5qaogDLOaqygLzT7EHdIr1iPS2+iYbN7OhNNpppg5z5ZuWPFXIMWfPMMfqA4R7T2fcSL5TqYHvfAwkh0XDq6knygn/iDIfOa2Qz05ySEB3kK5v4p1iG33vwOTjNrdIf+NCT2BETMaJn1P/pTUUyKTGSInlXz6xkVt+f2Xf/4I01MXcl5i5YF3Vo6UljdQqx57671RznDCcqxo9X++PkawLbZp6sKv5e4uGeS0aGjUbqjnFHK6owsqnDNlPbzzrUDbY7JbpHmNBKpxBcuhJ0+7qNZJwlBcbBaCKABB9KGKWKvIzdnSWXDORx/pM+5JZi6KY7ErmaqESqKSU/p4fX5psxszceV0+3VjttGsSdBnBC/3Grf7t7OYUvRpN6pnn3FQItJY4GzjWkWTwyYN2i24DfrK+qAbNeKjN6p8qUpawCdDcuWCgcuiJRpoa8vm0rjPz4ptlJq0+FG1GhQZnDuWSjEi+zWkfx7BmygK5BaKqQ5DEq/51Y9f7sCf4YzQrg2OqRvmm1l74ZMFEIUOwbKHTsdFCPUt14RcRDb8NgffX4Q== desktop-nano"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDYmR1aAHqYm7RXSHZ/RvAsSYqd9f2arExfjaDt1/3vCy3ohdqc1oBNATiz/MindEr+dRgCaJmU09alQ+E2ufYpaAr8VCThupEXvS4YmTXVOdwTEk5Dl40ht1PvMH4s8yxst4K/VFj9fvTjdkpFiG+s/iS/kbpYBDK7/FsVXy8uJ/CSzSLK5UUeKkuVbCrVXFnR3t9hlh9Wslavn2aPH4MrM0pjftiv5/srC7hYwlUA+IDazA9DxSkjHnd44pnev9Ge8ViF79D99BCeuFfuTvN6FnQmr0KJZJxhnoIjqflyzSV3fFFu18z4pnOds7Hs+pTfvzyrDr5+0Bgbb/c6TvBAg3M+N4CquH4FkYg4m1QJcOHt4d6I953DoycGACXPa0he1K6ub0Qt7VAniitdf6kQASSH9OpZQ0QuO3L6xbBFrrA8ZyXkwAR4EiW5A0xejn7vvWefrRUDUP2g8rb1tPsmpIwGtbccMID1cT6ikhfL67FZaZ2oGcChd+3FfFW1PegnErfu04HDOuZ5jx2ByIrlCF0qTdCP9k7zmYJcRTEGGyfC+s37Zd0uRT3aKcLBjT4ZT88o4K/5AAikoz0zZ3TYOxLwgejjWDAEfnpu5lZNzGJR3zaC1PvnJ4H8pQ6JHUdAPBoDAHMwHqpmBFQTL6EanSHLblrGhz4lUUtb+uJncw== keyring"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCg+tT2T3ZFcDFjk2QoqypiKRfhdJsG7OjVNyW/OwSZ411VuXYlF+CDLwaLMX1qC3nxM8UYwoiAWDMCTRB767ktzT4br8ZJYTzJ72XClTKZtEHVe2jZpDFIJFik8HEj1g1aTHm/u5h5gDaZAxjcKf9rqe+pB/K2afYZb+s7lzdL0s+lLvbvmPM7pREK8eo/OCbvisBg6u828HLn5tyB8/qPg0DfGQmfVbypwuwujLwhffIBW364qiuZn0nyvqPzaczqahFnkYjbzsC4NPaA/PkuM2uinqYUeW/W0GbeA1DVFcHpMEfBD748HMKAsKZdX5O5DN0bQdSIjJMnKPwNlfg9rnw87Iz5op1prlQwN4XY7OTXYDBq6X4/sh5GVB7QRw9NKclSuYE8EBGhF7a8FNaGaBXaN2B6G8VtLMbboJfQKQi678gwp/4ZL/yS61LHTTdDSAcsQd8WthnFW1GpRQ+HT0uRwY5xJmy/hxVnTzosLpkbr6AcWCw+9uDUaRXobtbqlCPuCzQdvOc7OYecc7xs+LQbbJlA2EhxYxW8Cnt9n2DNH4M/DLDKCP1QgWhenCdaVbBQfqNpx1Z5y6/JUR3A928YVb/qqC738utYLBwgr/K2CdFdQppiu46nXJTEb64pHx4qzrwvlrxQ6u2EGReLi/WQEmmg0RK74ndeMtvhmw== laptop-nano"
      ];
    };
    william = {
      uid = 1000;
      description = "William A. Kennington III";
      canRoot = true;
      loginMachines = [ "legend" "lake" ];
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

  remotes = [
    "nixos"
    "lake"
  ];

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

  sshHostKeys = {
    "atlas" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDEm1t3sNOBfXF7lupeNvZ50M5hT0DYiOiIAx0f+ZLmN";
    "atomic" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGYJVmfOh/DiRlZr3c29QRJY92oBXBRD9H4RLkeEcdQk";
    "elite" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHhgo8hnoGvRJN+kIVBMLc+WheSnRn1MWGXwKVdMnYOn";
    "exodus" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPriEVGsGu7DnUVa/aPFj+BccNP8KUmM9836My9YYemG";
    "ferrari" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5Q2HxW5RGFr9yi+UrrdfFh5oR7b6DdWbkYdoWoERM8";
    "nevada" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDG8rNK9ZRJl8brPEytBF7sCh2FBejt+V5u3TB3BwiG4";
    "newton" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIALFIS2Hu2bLEHzxcXpNa9JTRBwt/h1S7yjMdHK1FE4f";
    "page" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBv3UkLvr3OcB4fNXJlpNVDnAFgK1Sfgn8wyXoL+EiiS";
    "quest" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKooOFrPAREfP00RT5SM7EI0Y4bOKG07zu+o2vCNEeyJ";
    "legend" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmQ0vQjgxQ2Id4H6pTPyTbe6HvOfAP7NOabwgv8k0nh";
    "delta" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMXpH6rNL18r6ZRMrCogCTDPr7rsOH4FtK4lzzSs+wPv";
  };

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
          bmcMac = "0C:C4:7A:C8:FA:B6";
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
          bmcMac = "00:25:90:9d:df:e6";
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
        athena = {
          id = 38;
          vlans = [ "slan" ];
          bmcMac = "BC:5F:F4:C9:A0:70";
        };
      };
    };

    "nyc-1" = {
      pub4 = "192.81.218.";
      pub4Gateway = "192.81.218.1";
      pub4PrefixLength = 24;

      pub6 = "2604:a880:400:d0::";
      pub6Gateway = "2604:a880:400:d0::1";
      pub6PrefixLength = 64;

      priv4 = "10.100.";
      priv6 = "fd32:d318:c6fa:e153";

      pubDnsServers = [
        "8.8.8.8"
        "8.8.4.4"
      ];

      pubNtpServers = [
        { server = "clock.nyc.he.net"; weight = "5"; }
        { server = "clock.fmt.he.net"; weight = "2"; }
        { server = "clock.sjc.he.net"; weight = "2"; }
        { server = "0.us.pool.ntp.org"; weight = "1"; }
        { server = "1.us.pool.ntp.org"; weight = "1"; }
        { server = "2.us.pool.ntp.org"; weight = "1"; }
      ];

      timeZone = "America/New_York";

      gateways = [
        "jupiter"
      ];

      dhcpServers = [
        "jupiter"
      ];

      dnsServers = [
        "jupiter"
      ];

      ntpServers = [
        { server = "jupiter"; weight = "1"; }
      ];

      pub6MachineMap = {
        jupiter = "828:6001";
      };

      pub4MachineMap = {
        jupiter = 29;
      };

      internalMachineMap = {
        jupiter = {
          id = 31;
          vlans = [ "slan" "mlan" "tlan" ];
        };
      };
    };

    "mtv-w" = {
      priv4 = "10.1.";
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
        "exodus"
      ];

      dhcpServers = [
        "exodus"
      ];

      dnsServers = [
        "exodus"
      ];

      nases = [
        "exodus"
      ];

      nasIds = [
        8
        9
      ];

      consul = {
        servers = [ "exodus" ];
      };


      ntpServers = [
        { server = "exodus"; weight = "1"; }
      ];

      # Cannot use 1 as this is reserved for the default gateway
      internalMachineMap = {
        exodus = {
          id = 30;
          vlans = [ "slan" "mlan" "dlan" "ulan" "tlan" ];
          bmcMac = "0c:c4:7a:dd:00:42";
        };
        legend = {
          id = 33;
          vlans = [ "slan" "mlan" "dlan" ];
        };
        eagle = {
          id = 34;
          vlans = [ "dlan" ];
          bmcMac = "0c:c4:7a:dd:6e:be";
        };
      };
    };

  };
}

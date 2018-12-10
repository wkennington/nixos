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
      prodigy = 2;
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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFIj0z3VZwfoKutny7UxOQYQfDzWH3a1dyVgxv7Sl92P william@backup"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/j2j9UGnPPz22IU4szHRGqVVo5pzO1cGKFKaaG8KXV/gjXclhoBeTYhJCiv2JqoWyLQJpynU2IJnMAAmmKroGWSSamriU5Lk3dXWON5MTLKMTmcHeLx4AmVKjLp81RYXvq+yyP3/MZS6YirWarULLFQB0XeRkbM5vjbWFah9p0eDdTV0oedwz0rqFa9HFXdL+Vp04WbXQpr2+bQKR/4p4WFKoUpFyioceKdP2dF4y13x27NJH/dMVE/+gIU6B2fNyDie9ekZbBAjf0MUwz9eUDFqkm1uxZtL2yuOp3wv8QYAtrOKqWlx2UPDuubKCbrAhsWjWOag2Ju0qf4+d5DxPCtMzMFMTveFBpfq8tMT/nTo19qug1Hs2Mv/0J9pppS9OzTuyupaT7Sz9kEFsw4YZKUYF1UbyTDzAZ2tvFz2g27Isg6VADL8eDInNWfCzbomlEXn8bMxs1PFUPSxxZ5+f48mcBq850Qu+CiviMn2SxwCmuvmyBifr53ZU58uGw+ZYagn6uakpR1bwXUv14rSEd2/f7Vwk56l8UvqVdCpUBjFldXKYZi7qlaWQJ/7a4Sko7UlNE+wX+WWTTu7gtQaAd4vTZRXTre5DOqUnH5EvSmuAbFonyRwLO0G23QOraOAS0aYE2viMFmjaSlJp4H6eav9WzOvYFYCF5MJPms831Q== william@backup"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCvG/BCO3QI3l6j2KDRVKO3qcXEauLxCNTrloU2mqqy0XvdEfYYvnLWQ3p6WqqC1h8nEeuZRGlfQiYtdiLYUTVsEr6vax5kQMMpiIt46v9ZQEIg7oNElImMbJYezPsZ6m0kW0GVpPJYVs7N9JnCPuvmSZKzyyZStA6rPD5+4eRZvdpFwZ89ZPrIkfdwPLF44Q8EIl2hWrrvUJZ4qXBozPYZIIXyMDiRcMVsS9mGstmcKW9f3U3NyJDyoP5G8xKbdbxI/xVQNSdnR5MtD/utfQ/4GI9+F+pJ3TTZVm/II/gzG8hoB/7PDaGs0ONt9XRRrzKjQzUIOob/Rnhj4OtDGH8KVgbnB+Rpe+SMP4inIjmehrmZW2l4rdeVaYDFlESOVZuS0WM4VEhNo/9G7UIMXAGjSbI3PtV4b094tz1/g9YxGihxvJ2DKenDCUA98+dNMODIMFoOTqJEwBDpK/suFEhOs8HfqIPIQpT8VfXHwahq5tg+L/e9FMT1q2OJJNrGXMs/0CtHutB7szK65xC/XTuwtK9Z8PPGn13VI8u1UE4ZV7wZa5TkL9oWFlyXPRcHMde+WFxFgQ02K6PGRF0LFgEdDhVm8BUDAeBlK4k8QpyMM+hZf6bjaQHjHe0/u0c0fTha4AclGAMupR1CapzSDsaTmg3bDjKEFf3gZuWZRR8llw== william@keychain"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTgCTxC4LUon2NLsLpbIfM68NHO2rGmnRKA+vqE7AXxQ00wryhPJPngQl6c/nwHbm8v9Oi7IPAyuPXAFWoulO6PIxni1RH4k3o040vNIs32mzQY8234GMACYBevaT6nh5qaogDLOaqygLzT7EHdIr1iPS2+iYbN7OhNNpppg5z5ZuWPFXIMWfPMMfqA4R7T2fcSL5TqYHvfAwkh0XDq6knygn/iDIfOa2Qz05ySEB3kK5v4p1iG33vwOTjNrdIf+NCT2BETMaJn1P/pTUUyKTGSInlXz6xkVt+f2Xf/4I01MXcl5i5YF3Vo6UljdQqx57671RznDCcqxo9X++PkawLbZp6sKv5e4uGeS0aGjUbqjnFHK6owsqnDNlPbzzrUDbY7JbpHmNBKpxBcuhJ0+7qNZJwlBcbBaCKABB9KGKWKvIzdnSWXDORx/pM+5JZi6KY7ErmaqESqKSU/p4fX5psxszceV0+3VjttGsSdBnBC/3Grf7t7OYUvRpN6pnn3FQItJY4GzjWkWTwyYN2i24DfrK+qAbNeKjN6p8qUpawCdDcuWCgcuiJRpoa8vm0rjPz4ptlJq0+FG1GhQZnDuWSjEi+zWkfx7BmygK5BaKqQ5DEq/51Y9f7sCf4YzQrg2OqRvmm1l74ZMFEIUOwbKHTsdFCPUt14RcRDb8NgffX4Q== william@legend"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCdzDQF5OHFuHl4q0s/Uve9czn3xyj6dP11bAGTQduwCIH2UsDZ3ulAvdL/GuMWQetg6J2G5SvL0IAWSptd+goSYluMO1o6ZsQLBVqxJ3oBwZ56JXnIJb2luSvwsHRCerT5cGOvWbrKqjhwwjOC1O3eaAZBjv/e4PGEpcbmFu2e6BlfJOpcX8eu9nxS7C7tZ/i+Yxa9btsqYJIPd/ZsMn4f3BmDuupkECXFWmq868J63aliqMUaynYzWnnHP3WJVD40JmfYrYfe1VqWiPW/HUHwpPonIlWyQaLBNtdz+ORq8tTofbUdIebYH+QrptkFwr1DiwVVWpJHLP0CW6kEZz//8vZ3fR2MxcJex2d75NUMAluNZ93NDO4EYsr1FRvoX1znURloPBdV/y8chtar1jpeUzTwvTwQubpfXrW3w5Qobt+O/BDPgAOG+WQR0fFTBULJinIs5si+UwOzi9qhuuF/a9s1d1rRNDHlhE6iIEPa/OqJWqGssg4f5sIo6qYmJ51CrGrz/Z25IPq+haN5LJ1UJh4kj7MRy81YhwSupmSTCReUYEjqvGT6vEfYMspKMu1hsD9CrfDSdyBaeX3YQudNzN09E8yS0ANgu4ijTT8j6a/ldKFlorqLcO24pRlEaJDnzrd+pulgFSJ6nc8qFx36CnuH2YeRlDYIOgMyVV8fZw== william@lotus"
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

  remotes = [
    "nixos"
    "prodigy"
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

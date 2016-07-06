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

  vpn = {
    # Assumes a prefix of /24
    subnet = "192.168.17.";
    idMap = {
      prodigy = 2;
      atomic = 3;
      legend = 4;
      newton = 8;
      page = 9;
      quest = 10;
      elite = 11;
    };
  };

  domain = "wak.io";

  consulAclDc = "fmt-1";

  userInfo = {
    william = {
      uid = 1000;
      description = "William A. Kennington III";
      canRoot = true;
      loginMachines = [ "legend" "prodigy" ];
      canShareData = true;
    };
    bill = {
      uid = 1001;
      description = "William A. Kennington Jr";
      canRoot = false;
      loginMachines = [ ];
      canShareData = true;
    };
    linda = {
      uid = 1002;
      description = "Linda D. Kennington";
      canRoot = false;
      loginMachines = [ ];
      canShareData = true;
    };
    ryan = {
      uid = 1003;
      description = "Ryan C. Kennington";
      canRoot = false;
      loginMachines = [ ];
      canShareData = true;
    };
    sumit = {
      uid = 1004;
      description = "Sumit R. Punjabi";
      canRoot = false;
      loginMachines = [ ];
      canShareData = true;
    };
  };

  remotes = [ "nixos" "prodigy" ];

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

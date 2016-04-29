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
    "0.pool.ntp.org"
    "1.pool.ntp.org"
    "2.pool.ntp.org"
    "3.pool.ntp.org"
  ];

  # netMaps currently assumes /16 ipv4 and /60 ipv6 allocations
  # ip processing in nix is hard :/
  netMaps = {
    "abe-p" = {
      priv4 = "10.0.";
      pub6 = "2001:470:88fa:000";
      priv6 = "fda4:941a:81b5:000";

      timeZone = "America/New_York";

      pubDnsServers = [
        "8.8.8.8"
        "8.8.4.4"
      ];

      pubNtpServers = [
        "clock.nyc.he.net"
        "0.us.pool.ntp.org"
        "1.us.pool.ntp.org"
        "2.us.pool.ntp.org"
      ];

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
        "atomic"
      ];

      internalMachineMap = {
        atomic = { id = 2; vlans = [ "slan" "mlan" "dlan" "ulan" "tlan" ]; };
        elite = { id = 31; vlans = [ "slan" "dlan" ]; };
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
      priv6 = "fda4:941a:81b5:100";

      pubDnsServers = [
        "8.8.8.8"
        "8.8.4.4"
      ];

      pubNtpServers = [
        "clock.fmt.he.net"
        "clock.sjc.he.net"
        "clepsydra.dec.com"
        "clock.via.net"
        "tock.gpsclock.com"
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
        "newton"
        "page"
        "quest"
      ];

      ceph = {
        fsId = "40d2204b-4833-4249-ae3e-308c0c8171cb";
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
        "clock.fmt.he.net"
        "clock.sjc.he.net"
        "clepsydra.dec.com"
        "clock.via.net"
        "tock.gpsclock.com"
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
        "lazarus"
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

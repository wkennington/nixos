{ lib, ... }:
with lib;
rec {
  gateway = {
    dhcpRange = {
      lower = 100;
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
      jester = 1;
      prodigy = 2;
      atomic = 3;
      alamo = 4;
      ferrari = 5;
      delta = 6;
      legend = 7;
      newton = 8;
      page = 9;
      quest = 10;
    };
  };

  domain = "wak.io";

  consulAclDc = "fmt-1";

  userInfo = {
    william = {
      uid = 1000;
      description = "William A. Kennington III";
      canRoot = true;
      loginMachines = [ "exodus" "prodigy" ];
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

  remotes = [ "nixos" "prodigy" "jester" ];

  # netMaps currently assumes /16 ipv4 and /60 ipv6 allocations
  # ip processing in nix is hard :/
  netMaps = {
    "abe-p" = {
      priv4 = "10.0.";
      pub6 = "2001:470:88fa:000";
      priv6 = "fda4:941a:81b5:000";

      timeZone = "America/New_York";

      # Must start at 2 for multiple
      # Can be one for a single gateway
      gatewayMap = {
        atomic = 2;
      };

      internalMachineMap = {
        atomic = 2;
      };
    };

    "fmt-1" = {
      pub4 = "65.19.134.";
      pub4Gateway = "65.19.134.241";
      pub4PrefixLength = 28;

      priv4 = "10.2.";
      pub6 = "2001:470:810a:000";
      priv6 = "fda4:941a:81b5:100";

      timeZone = "America/Los_Angeles";

      gateways = [
        "newton"
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

      ceph = {
        fsId = "40d2204b-4833-4249-ae3e-308c0c8171cb";
        mons = [ "newton" "page" "quest" ];
        osds = {
          "delta" = [ ];
          "ferrari" = [ ];
        };
      };

      consul = {
        servers = [ "newton" "page" "quest" ];
      };

      zookeeper = {
        # Numbering is important and should be consistent in
        # the cluster. Therefore it is recommended never to reuse
        # or reorganize the numeric values for nodes.
        servers = {
          newton = 0;
          page = 1;
          quest = 2;
        };
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
        sw1g1 = { id = 11; vlans = [ "mlan" ]; };
        sw10g1 = { id = 21; vlans = [ "mlan" ]; };
        newton = { id = 31; vlans = [ "slan" "mlan" "tlan" ]; };
        page = { id = 32; vlans = [ "slan" "mlan" "tlan" ]; };
        quest = { id = 33; vlans = [ "slan" "mlan" "tlan" ]; };
        delta = { id = 34; vlans = [ "slan" ]; };
        ferrari = { id = 35; vlans = [ "slan" ]; };
        hunter = { id = 36; vlans = [ "slan" ]; };
        fuel = { id = 37; vlans = [ "slan" ]; };
        eagle = { id = 38; vlans = [ "slan" ]; };
        lithium = { id = 39; vlans = [ "slan" ]; };
        marble = { id = 40; vlans = [ "slan" ]; };
      };
    };

    "mtv-w" = {
      priv4 = "10.1.";
      pub6 = "2001:470:810a:000";
      priv6 = "fda4:941a:81b5:100";

      timeZone = "America/Los_Angeles";

      gateways = [
        "alamo"
      ];

      dhcpServers = [
        "alamo"
      ];

      dnsServers = [
        "alamo"
      ];

      consul = {
        servers = [ "alamo" ];
      };

      # Cannot use 1 as this is reserved for the default gateway
      internalMachineMap = {
        kvm = { id = 9; vlans = [ "mlan" ]; };
        alamo = { id = 31; vlans = [ "slan" "mlan" "dlan" "ulan" ]; };
        exodus = { id = 32; vlans = [ "slan" ]; };
      };

    };
  };
}

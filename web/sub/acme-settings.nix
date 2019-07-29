{ lib, ... }:

with lib;
{
  options = {

    acmeServers = mkOption {
      type = types.listOf types.string;
      default = [
        "localhost:81"
      ];
    };

  };
}

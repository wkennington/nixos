{ lib, ... }:

with lib;
{
  options = {

    serialConsole = mkOption {
      default = null;
      type = types.nullOr types.int;
    };

  };
}

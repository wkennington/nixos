{ lib, ... }:

with lib;
{
  options = {

    serialConsole = mkOption {
      type = types.nullOr types.int;
    };

  };
}

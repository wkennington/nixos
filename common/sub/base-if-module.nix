{ lib, ... }:
with lib;
{
  options = {
    myNatIfs = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };
}

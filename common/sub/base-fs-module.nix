{ lib, ... }:
with lib;
{
  options = {
    rootUUID = mkOption {
      default = null;
      type = types.nullOr types.str;
    };
  };
}

{ lib, ... }:

let
  inherit (lib)
    mkOption
    types;
in
{
  options = {

    myCtdbd = {
      
      enable = mkOption {
        type = types.bool;
        default = false;
      };

    };

  };
}

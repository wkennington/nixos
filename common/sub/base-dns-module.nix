{ config, lib, ... }:
with lib;
{
  options = {
    myDns = rec {
      forwardZones = mkOption {
        default = [ ];
        type = types.attrsOf (types.listOf types.optionSet);
        options = {
          zone = mkOption {
            server = mkOption {
              type = types.str;
            };

            port = mkOption {
              type = types.int;
            };
          };
        };
      };

      forwardZones' = mkOption {
        default = [ ];
        type = types.listOf types.str;
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = config.myDns.forwardZones' == attrNames config.myDns.forwardZones;
        message = "Not all of the forward zones were processed";
      }
    ];
  };
}

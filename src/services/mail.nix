{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    services.postfix = {
	  enable = false;
      origin = config.networking.fqdn;
    };
  };
  meta = {};
}

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
    security.acme = {
      defaults = {
        email = "admin@${config.networking.fqdn}";
      };
      acceptTerms = true;
    };
  };
  meta = {};
}

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
    services.grocy = {
      enable = false;
      hostName = "groceries.home.${config.networking.fqdn}";
      nginx.enableSSL = true;
    };
  };
  meta = {};
}

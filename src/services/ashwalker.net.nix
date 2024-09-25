{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  net = config.services."ashwalker-net";
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    services."ashwalker-net" = {
      enable = true;
      domain = "${config.networking.fqdn}";
    };
    services.nginx.virtualHosts."${net.domain}" = {
      enableACME = config.networking.domain != "local";
      addSSL = config.networking.domain != "local";
      default = true;
    };
  };
  meta = {};
}

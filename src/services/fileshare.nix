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
    services.nginx.virtualHosts."share.ashwalker.net" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        root = "/var/lib/nginx-fileshare";
        basicAuthFile = "/etc/nginx/fileshare.htpasswd";
        extraConfig = ''
          autoindex on;
        '';
      };
    };
  };
  meta = {};
}

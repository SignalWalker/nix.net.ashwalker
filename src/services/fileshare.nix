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
    virtualHosts."share.ashwalker.net" = {
      enableACME = true;
      forceSSL = true;
      listenAddresses = nginx.publicListenAddresses;
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

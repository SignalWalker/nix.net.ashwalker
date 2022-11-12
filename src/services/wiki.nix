{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  vhost = "wiki.${config.networking.fqdn}";
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    age.secrets.wikiAdminPassword = {
      file = ./wiki/wikiAdminPassword.age;
    };
    services.mediawiki = {
      enable = false;
      name = "SignalWiki";
      passwordFile = config.age.secrets.wikiAdminPassword.path;
      virtualHost = {
        hostName = vhost;
        forceSSL = true;
        enableACME = true;
        adminAddr = "admin@${vhost}";
      };
    };
  };
  meta = {};
}

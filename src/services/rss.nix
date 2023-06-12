{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  vhost = "rss.${config.networking.fqdn}";
in {
  options = with lib; {};
  disabledModules = [];
  imports = [
    ./rss/bridge.nix
  ];
  config = {
    age.secrets.rssUserPassword = {
      file = ./rss/rssUserPassword.age;
      owner = "freshrss";
    };
    age.secrets.rssDbPassword = {
      file = ./rss/rssDbPassword.age;
      owner = "freshrss";
    };
    services.freshrss = {
      enable = true;
      virtualHost = vhost;
      baseUrl = "https://${config.services.freshrss.virtualHost}";
      database = {
        type = "sqlite";
        passFile = config.age.secrets.rssDbPassword.path;
      };
      defaultUser = "ash";
      passwordFile = config.age.secrets.rssUserPassword.path;
    };
    services.nginx.virtualHosts."${vhost}" = {
      enableACME = config.networking.domain != "local";
      forceSSL = config.networking.domain != "local";
    };
  };
  meta = {};
}

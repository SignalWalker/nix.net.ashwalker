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
  imports = [];
  config = {
    services.tt-rss = {
      enable = true;
      pubSubHubbub.enable = true;
      selfUrlPath = "https://${config.services.tt-rss.virtualHost}";
      registration = {
        enable = false;
        notifyAddress = "ash@ashwalker.net";
        maxUsers = 0;
      };
      virtualHost = vhost;
      database.type = "pgsql";
    };
    age.secrets.ttrssEnvironment.file = ./rss/ttrssEnvironment.age;
    systemd.services.phpfpm-tt-rss.serviceConfig.EnvironmentFile = config.age.secrets.ttrssEnvironment.path;
    systemd.services.tt-rss.serviceConfig.EnvironmentFile = config.age.secrets.ttrssEnvironment.path;
    services.rss-bridge = {
      enable = true;
      user = "rssbridge";
      group = "rssbridge";
      virtualHost = "bridge.${vhost}";
      whitelist = ["*"];
    };
    users.users.rssbridge = {
      isSystemUser = true;
      group = "rssbridge";
    };
    users.groups.rssbridge = {};
    # services.freshrss = {
    # 	enable = true;
    # 	virtualHost = "rss.${config.networking.fqdn}";
    # 	baseUrl = "https://${config.services.freshrss.virtualHost}";
    # 	database = {
    # 		type = "sqlite";
    # 		passFile = config.age.secrets.freshrssDbPassword.path;
    # 	};
    # 	defaultUser = "ash";
    # 	passwordFile = config.age.secrets.rssUserPassword.path;
    # };
    # age.secrets.freshrssPassword.owner = "freshrss";
    # age.secrets.freshrssDbPassword.owner = "freshrss";
    services.nginx.virtualHosts."${vhost}" = {
      enableACME = true;
      forceSSL = true;
    };
    services.nginx.virtualHosts."bridge.${vhost}" = {
      enableACME = true;
      forceSSL = true;
    };
  };
  meta = {};
}

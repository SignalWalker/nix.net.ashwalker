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
    services.tt-rss = {
      enable = true;
      pubSubHubbub.enable = true;
      selfUrlPath = "https://${config.services.tt-rss.virtualHost}";
      registration = {
        enable = true;
        notifyAddress = "ash@ashwalker.net";
        maxUsers = 0;
      };
      auth = {
        autoLogin = false;
      };
      virtualHost = "rss.${config.networking.fqdn}";
    };
    # services.freshrss = {
    # 	enable = true;
    # 	virtualHost = "rss.${config.networking.fqdn}";
    # 	baseUrl = "https://${config.services.freshrss.virtualHost}";
    # 	database = {
    # 		type = "sqlite";
    # 		passFile = config.age.secrets.freshrssDbPassword.path;
    # 	};
    # 	defaultUser = "ash";
    # 	passwordFile = config.age.secrets.freshrssPassword.path;
    # };
    # age.secrets.freshrssPassword.owner = "freshrss";
    # age.secrets.freshrssDbPassword.owner = "freshrss";
    services.nginx.virtualHosts."${config.services.tt-rss.virtualHost}" = {
      enableACME = true;
      forceSSL = true;
    };
  };
  meta = {};
}

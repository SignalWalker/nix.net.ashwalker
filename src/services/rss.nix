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
    };
	age.secrets.ttrssEnvironment.file = ../../secrets/ttrssEnvironment;
	systemd.services.phpfpm-tt-rss = {
		serviceConfig = {
			EnvironmentFile = age.secrets.ttrssEnvironment.path;
		};
	};
	services.rss-bridge = {
		enable = true;
		user = "rssbridge";
		group = "rssbridge";
		virtualHost = "bridge.${vhost}";
		whitelist = [ "*" ];
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
	# 	passwordFile = config.age.secrets.rssUserPassword.path;
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

{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  bridge = config.services.rss-bridge;
  nginx = config.services.nginx;
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    age.secrets.rssBridgePassword = {
      file = ./rssBridgePassword.age;
      owner = nginx.user;
      group = nginx.group;
    };
    services.rss-bridge = {
      enable = true;
      user = "rssbridge";
      group = "rssbridge";
      virtualHost = null;
      whitelist = ["AO3" "Bandcamp Bridge" "Github Repositories Search" "NyaaTorrents"];
    };
    users.users.${bridge.user} = {
      isSystemUser = true;
      group = bridge.group;
    };
    users.groups.${bridge.group} = {};
    services.phpfpm.pools.${bridge.pool} = {
      settings = {
        "listen.owner" = nginx.user;
        "listen.group" = nginx.group;
      };
    };
    services.nginx.virtualHosts."rss-bridge.${config.networking.fqdn}" = {
      root = "${pkgs.rss-bridge}";
      basicAuthFile = config.age.secrets.rssBridgePassword.path;
      locations."/" = {
        tryFiles = "$uri /index.php$is_args$args";
      };
      locations."~ ^/index.php(/|$)" = {
        extraConfig = ''
          include ${nginx.package}/conf/fastcgi_params;
          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          fastcgi_pass unix:${config.services.phpfpm.pools.${bridge.pool}.socket};
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          fastcgi_param RSSBRIDGE_DATA ${bridge.dataDir};
        '';
      };
    };
  };
  meta = {};
}

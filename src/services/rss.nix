{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  rss = config.signal.rss;
  psql = config.services.postgresql;
in {
  options = with lib; {
    signal.rss = {
      enable = (mkEnableOption "rss aggregator") // {default = true;};
      hostName = mkOption {
        type = types.str;
        default = "rss.${config.networking.fqdn}";
      };
      user = mkOption {
        type = types.str;
        default = "freshrss";
      };
      group = mkOption {
        type = types.str;
        default = "freshrss";
      };
      database = {
        name = mkOption {
          type = types.str;
          default = "freshrss";
        };
      };
    };
  };
  disabledModules = [];
  imports = [
    ./rss/bridge.nix
  ];
  config = lib.mkIf rss.enable {
    age.secrets.rssUserPassword = {
      file = ./rss/rssUserPassword.age;
      owner = rss.user;
    };
    age.secrets.rssDbPassword = {
      file = ./rss/rssDbPassword.age;
      owner = rss.user;
    };
    services.postgresql = {
      ensureDatabases = [rss.database.name];
      ensureUsers = [
        {
          name = rss.user;
          ensureClauses.login = true;
          ensurePermissions."DATABASE ${rss.database.name}" = "ALL PRIVILEGES";
        }
      ];
    };
    services.freshrss = {
      enable = true;
      user = rss.user;
      # group = rss.group;
      virtualHost = rss.hostName;
      baseUrl = "https://${rss.hostName}";
      database = {
        type = "pgsql";
        user = rss.user;
        name = rss.database.name;
        port = psql.port;
        host = "localhost";
        passFile = config.age.secrets.rssDbPassword.path;
      };
      defaultUser = "ash";
      passwordFile = config.age.secrets.rssUserPassword.path;
    };
    services.nginx.virtualHosts.${rss.hostName} = {
      # addSSL = true;
      forceSSL = true;
    };
  };
  meta = {};
}

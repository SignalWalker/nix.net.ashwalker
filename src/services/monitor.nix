{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  grafana = config.services.grafana;
  psql = config.services.postgresql;
  secrets = config.age.secrets;
in {
  options = with lib; {
    services.grafana = {
      user = mkOption {
        type = types.str;
        readOnly = true;
        default = "grafana";
      };
      group = mkOption {
        type = types.str;
        readOnly = true;
        default = "grafana";
      };
    };
  };
  disabledModules = [];
  imports = [];
  config = lib.mkIf false {
    age.secrets.grafanaDbPassword = {
      file = ./monitor/grafanaDbPassword.age;
      owner = grafana.user;
      group = grafana.group;
    };
    age.secrets.grafanaAdminPassword = {
      file = ./monitor/grafanaAdminPassword.age;
      owner = grafana.user;
      group = grafana.group;
    };
    age.secrets.grafanaSecretKey = {
      file = ./monitor/grafanaSecretKey.age;
      owner = grafana.user;
      group = grafana.group;
    };
    services.prometheus = {
      enable = true;
    };
    services.grafana = {
      enable = true;
      settings.server = {
        http_addr = "127.0.0.1";
        http_port = 2342;
        domain = "monitor.${config.networking.fqdn}";
        enable_gzip = true;
      };
      settings.analytics = {
        reporting_enabled = false;
      };
      settings.security = {
        admin_password = "$__file{${secrets.grafanaAdminPassword.path}}";
        secret_key = "$__file{${secrets.grafanaSecretKey.path}}";
      };
      settings.database = {
        type = "postgres";
        host = "127.0.0.1:${toString psql.port}";
        user = grafana.user;
        password = "$__file{${secrets.grafanaDbPassword.path}}";
      };
    };
    services.nginx.virtualHosts.${grafana.settings.server.domain} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString grafana.settings.server.port}";
        proxyWebsockets = true;
      };
    };
  };
  meta = {};
}

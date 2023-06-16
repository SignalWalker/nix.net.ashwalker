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
  config = {
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
    services.postgresql = {
      ensureDatabases = [grafana.settings.database.name];
      ensureUsers = [
        {
          name = grafana.settings.database.user;
          ensurePermissions."DATABASE ${grafana.settings.database.name}" = "ALL PRIVILEGES";
        }
      ];
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
        admin_user = "Ash";
        admin_password = "$__file{${secrets.grafanaAdminPassword.path}}";
        admin_email = "admin@${config.networking.fqdn}";
        secret_key = "$__file{${secrets.grafanaSecretKey.path}}";
        cookie_secure = true;
        strict_transport_security = true;
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
        proxyPass = "http://localhost:${toString grafana.settings.server.http_port}";
        proxyWebsockets = true;
      };
    };
  };
  meta = {};
}

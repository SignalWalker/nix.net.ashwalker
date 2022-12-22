{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  hostName = "cloud.${config.networking.fqdn}";
  cfg = config.signal.services.cloud;
  nc = config.services.nextcloud;
in {
  options.signal.services.cloud = with lib; {
    enable = mkEnableOption "cloud";
  };
  disabledModules = [];
  imports = [];
  config = lib.mkIf cfg.enable {
    services.nextcloud = {
      enable = true;
      inherit hostName;
      https = true;
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        adminpassFile = config.age.secrets.cloudAdminPassword.path;
        adminuser = "admin";
      };
    };
    services.nginx.virtualHosts.${hostName} = {
      enableACME = config.networking.domain != "local";
      forceSSL = config.networking.domain != "local";
    };
    services.postgresql = {
      ensureDatabases = [nc.config.dbname];
      ensureUsers = [
        {
          name = nv.config.dbuser;
          ensurePermissions."DATABASE ${nc.config.dbname}" = "ALL PRIVILEGES";
        }
      ];
    };
    systemd.services."nextcloud-setup" = {
      requires = ["postgresql.service"];
      after = ["postgresql.service"];
    };
  };
  meta = {};
}

{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  hostName = "cloud.${config.networking.fqdn}";
  cloud = config.signal.services.cloud;
  nc = config.services.nextcloud;
in {
  options.signal.services.cloud = with lib; {
    enable = (mkEnableOption "cloud") // {default = true;};
  };
  disabledModules = [];
  imports = [];
  config = lib.mkIf cloud.enable {
    age.secrets.cloudAdminPassword = {
      file = ./cloud/cloudAdminPassword.age;
      owner = "nextcloud";
      group = "nextcloud";
    };
    services.nextcloud = {
      enable = true;
      inherit hostName;
      https = config.networking.domain != "local";
      package = pkgs.nextcloud25;
      autoUpdateApps.enable = true;
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        adminpassFile = config.age.secrets.cloudAdminPassword.path;
        adminuser = "admin";
        overwriteProtocol =
          if nc.https
          then "https"
          else null;
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

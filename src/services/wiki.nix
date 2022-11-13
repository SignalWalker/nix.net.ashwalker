{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  vhost = "wiki.${config.networking.fqdn}";
  wiki = config.services.mediawiki;
  phpfpm = config.services.phpfpm.pools.mediawiki;
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    age.secrets.wikiAdminPassword = {
      file = ./wiki/wikiAdminPassword.age;
    };
    age.secrets.wikiDbPassword = {
      file = ./wiki/wikiDbPassword.age;
    };
    services.mediawiki = {
      enable = false;
      name = "SignalWiki";
      passwordFile = config.age.secrets.wikiAdminPassword.path;
      database = {
        type = "postgres";
        passwordFile = config.age.secrets.wikiDbPassword.path;
        port = config.services.postgresql.port;
      };
      virtualHost = {
        forceSSL = true;
        adminAddr = "admin@${vhost}";
      };
    };
    services.postgresql = {
      ensureUsers = {
        name = wiki.database.user;
        ensurePermissions = {"DATABASE ${wiki.database.name}" = "ALL PRIVILEGES";};
      };
      ensureDatabases = [wiki.database.name];
    };
    systemd.services.mediawiki-init = {
      after = ["postgresql.service"];
    };
    services.httpd.enable = lib.mkForce false; # services.mediawiki enables this by default
    services.phpfpm.pools.mediawiki = {
      settings."listen.owner" = lib.mkForce config.services.nginx.user;
      settings."listen.group" = lib.mkForce config.services.nginx.group;
    };
    services.nginx = {
      virtualHosts.${vhost} = {
        enableACME = true;
        forceSSL = wiki.virtualHost.forceSSL;
        root = "${config.services.mediawiki.package}/share/mediawiki";
        location."/" = {
          tryFiles = "$uri $uri/ @rewrite";
        };
        location."@rewrite" = {
          extraConfig = ''
            rewrite ^/(.*)$ /index.php?title=$1&$args;
          '';
        };
        location."^~ /maintenance/" = {
          return = "403";
        };
        location."/rest.php" = {
          tryFiles = "$uri $uri/ /rest.php?$args";
        };
        location."~ \\.php$" = {
          fastcgiParams."SCRIPT_FILENAME" = "$request_filename";
          extraConfig = ''
            include fastcgi_params;
            fastcgi_pass unix:${phpfpm.socket};
          '';
        };
        location."~* \\.(js|css|png|jpg|jpeg|gif|ico)$" = {
          tryFiles = "$uri /index.php";
          extraConfig = ''
            expires max;
            log_not_found off;
          '';
        };
        location."/_.gif" = {
          extraConfig = ''
            expires max;
            empty_gif;
          '';
        };
        location."^~ /cache/" = {
          extraConfig = ''
            deny all;
          '';
        };
        location."/dumps" = {
          root = "/var/lib/mediawiki/local";
          extraConfig = ''
            autoindex on;
          '';
        };
      };
    };
  };
  meta = {};
}

{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  domain = "src.${config.networking.fqdn}";
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    services.sourcehut = {
      enable = true;

      nginx = {
        enable = config.services.nginx.enable;
        virtualHost = {
          forceSSL = true;
        };
      };
      postgresql.enable = config.services.postgresql.enable;
      postfix.enable = config.services.postfix.enable;
      redis.enable = true;

      settings."sr.ht" = {
        environment = "production";
        global-domain = domain;
        origin = "https://${domain}";
        network-key = config.age.secrets.srcNetworkKey.path;
      };
      settings.webhooks.private-key = config.age.secrets.srcWebhookKey.path;

      meta.enable = true;
      settings."meta.sr.ht" = {};

      git.enable = false;
      settings."git.sr.ht" = {};

      hg.enable = false;
      settings."hg.sr.ht" = {};

      hub.enable = false;
      settings."hub.sr.ht" = {};

      todo.enable = false;
      settings."todo.sr.ht" = {};
    };

    security.acme.certs.${domain}.extraDomainNames = map (srv: "${srv}.${domain}") config.services.sourcehut.services;

    services.nginx.virtualHosts =
      foldl'
      (acc: srvc: std.recursiveUpdate acc {"meta.${domain}".useACMEHost = domain;})
      {"${domain}".enableACME = true;}
      config.services.sourcehut.services;
  };
  meta = {};
}

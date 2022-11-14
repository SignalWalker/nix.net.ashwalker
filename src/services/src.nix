{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  domain = "src.${config.networking.fqdn}";
  srht = config.services.sourcehut;
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    age.secrets = {
      srcNetworkKey = {file = ./src/srcNetworkKey.age;};
      srcServiceKey = {file = ./src/srcServiceKey.age;};
      srcWebhookKey = {file = ./src/srcWebhookKey.age;};
      srcMailKey = {
        file = ./src/srcMailKey.age;
        owner = srht.meta.user;
      };
    };
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
        service-key = config.age.secrets.srcServiceKey.path;
        owner-email = "admin@${domain}";
        owner-name = "Ash Walker";
      };
      settings.webhooks.private-key = config.age.secrets.srcWebhookKey.path;

      settings.mail = {
        pgp-key-id = "mail.src.ashwalker.net";
        pgp-pubkey = toString ./src/srcMailPubKey.key; # the toString is load-bearing
        pgp-privkey = config.age.secrets.srcMailKey.path;
        smtp-from = "daemon@${domain}";
      };

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

    security.acme.certs.${domain}.extraDomainNames = map (srv: "${srv}.${domain}") srht.services;

    services.nginx.virtualHosts =
      foldl'
      (acc: srvc: std.recursiveUpdate acc {"meta.${domain}".useACMEHost = domain;})
      {"${domain}".enableACME = true;}
      srht.services;
  };
  meta = {};
}

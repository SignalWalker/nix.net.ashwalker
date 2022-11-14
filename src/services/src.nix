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
    age.secrets = {
      srcNetworkKey = {file = ./src/srcNetworkKey.age;};
      srcServiceKey = {file = ./src/srcServiceKey.age;};
      srcWebhookKey = {file = ./src/srcWebhookKey.age;};
      srcMailKey = {file = ./src/srcMailKey.age;};
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
        pgp-pubkey = ''
          -----BEGIN PGP PUBLIC KEY BLOCK-----

          mDMEY3KZiBYJKwYBBAHaRw8BAQdALDVoGsmAFtbybN98M78KCsiM60sKvgfmv40n
          i5Dt1Py0Vm1haWwuc3JjLmFzaHdhbGtlci5uZXQgKHNyYy5hc2h3YWxrZXIubmV0
          IG1haWwgZGFlbW9uKSA8bWFpbC5kYWVtb25Ac3JjLmFzaHdhbGtlci5uZXQ+iJAE
          ExYIADgWIQTK8BOymNg8JCPOUGfN8ISEdKEe9AUCY3KZiAIbAwULCQgHAgYVCgkI
          CwIEFgIDAQIeAQIXgAAKCRDN8ISEdKEe9LvqAP9jL+RehM2gITTLtBR8b6h4HToy
          iTEB2mBU2zLpPKka5wD/Z5qJ77v+4pBc8TVxozG4oG/3B3DcU8hoUFZFSA5NwAS4
          OARjcpmIEgorBgEEAZdVAQUBAQdAH7piGDgBAyor9TLCkZzCJbv5nOI47jTIsoLx
          Xj4zmwQDAQgHiHgEGBYIACAWIQTK8BOymNg8JCPOUGfN8ISEdKEe9AUCY3KZiAIb
          DAAKCRDN8ISEdKEe9AoBAQCj4fuRfiM2IGF+t697yLv5dXeedM+cN8Pg/v8xLkUQ
          vAD+MwCvV2iohI3ZV9jQjOwR9BTHoVhkZtqIMTUBEJGDsw4=
          =AeB1
          -----END PGP PUBLIC KEY BLOCK-----
        '';
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

    security.acme.certs.${domain}.extraDomainNames = map (srv: "${srv}.${domain}") config.services.sourcehut.services;

    services.nginx.virtualHosts =
      foldl'
      (acc: srvc: std.recursiveUpdate acc {"meta.${domain}".useACMEHost = domain;})
      {"${domain}".enableACME = true;}
      config.services.sourcehut.services;
  };
  meta = {};
}

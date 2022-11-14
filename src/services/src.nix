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
  config =
    lib.mkMerge [
      {
        services.sourcehut = {
          enable = false;

          postgresql.enable = config.services.postgresql.enable;
          postfix.enable = config.services.postfix.enable;

          settings."sr.ht" = {
            environment = "production";
            global-domain = domain;
            origin = "https://${domain}";
            network-key = config.age.secrets.srcNetworkKey.path;
          };
          settings.webhooks.private-key = config.age.secrets.srcWebhookKey.path;

          nginx = {
            enable = config.services.nginx.enable;
            virtualHost = {
              enableACME = true;
              forceSSL = true;
            };
          };

          meta.enable = true;
          settings."meta.sr.ht" = {};

          git.enable = true;
          settings."git.sr.ht" = {};

          hg.enable = false;
          settings."hg.sr.ht" = {};

          hub.enable = false;
          settings."hub.sr.ht" = {};

          todo.enable = false;
          settings."todo.sr.ht" = {};
        };

        services.nginx.virtualHosts."${domain}".enableACME = true;
      }
    ]
    ++ (map (srvc: let
        srvdn = "${srvc}.${domain}";
      in {
        security.acme.certs.${domain}.extraDomainNames = [srvdn];
        services.nginx.virtualHosts."${srvdn}".useACMEHost = domain;
      })
      ["meta" "git"]);
  meta = {};
}

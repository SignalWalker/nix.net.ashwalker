{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  fqdn = "mail.${config.networking.fqdn}";
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    age.secrets.mailPasswordAsh = {
      file = ./mail/mailPasswordAsh.age;
    };
    age.secrets.mailPasswordDaemon = {
      file = ./mail/mailPasswordDaemon.age;
    };
    # workaround for https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/issues/275
    services.dovecot2.sieve.extensions = ["fileinto"];
    # from `simple-nixos-mailserver`
    mailserver = {
      enable = true;
      inherit fqdn;
      sendingFqdn = config.networking.fqdn;
      certificateScheme = "acme-nginx";
      domains = [config.networking.fqdn];
      localDnsResolver = false;
      loginAccounts = {
        "ash@${config.networking.fqdn}" = {
          hashedPasswordFile = config.age.secrets.mailPasswordAsh.path;
          aliases = [
            "postmaster@${config.networking.fqdn}"
            "abuse@${config.networking.fqdn}"
            "admin@${config.networking.fqdn}"
          ];
        };
        "daemon@${config.networking.fqdn}" = {
          hashedPasswordFile = config.age.secrets.mailPasswordDaemon.path;
        };
      };
    };
  };
  meta = {};
}

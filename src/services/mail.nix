{
  config,
  pkgs,
  lib,
  ...
}:
with builtins;
let
  std = pkgs.lib;
  fqdn = "mail.${config.networking.fqdn}";
in
{
  options = with lib; { };
  disabledModules = [ ];
  imports = [ ];
  config = {
    age.secrets.mailPasswordAsh = {
      file = ./mail/mailPasswordAsh.age;
    };
    age.secrets.mailPasswordDaemon = {
      file = ./mail/mailPasswordDaemon.age;
    };

    # from `simple-nixos-mailserver`
    mailserver = {
      enable = true;

      inherit fqdn;
      sendingFqdn = config.networking.fqdn;

      certificateScheme = "acme-nginx";

      domains = [ config.networking.fqdn ];

      # localDnsResolver = false;

      enableImap = true;
      enableImapSsl = true;
      enableSubmission = true;
      enableSubmissionSsl = true;

      enableManageSieve = true;

      indexDir = "/var/cache/dovecot/indices";
      fullTextSearch = {
        enable = false;
        autoIndex = true;
      };

      monitoring = {
        enable = true;
        alertAddress = "ashurstwalker@gmail.com";
      };

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
  meta = { };
}

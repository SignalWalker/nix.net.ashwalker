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
    # from `simple-nixos-mailserver`
    mailserver = {
      enable = true;
      inherit fqdn;
      certificateScheme = "acme-nginx";
      domains = [config.networking.fqdn];
      loginAccounts = {
        "ash@${config.networking.fqdn}" = {
          hashedPasswordFile = config.age.secrets.mailPasswordAsh.path;
          aliases = [
            "postmaster@${config.networking.fqdn}"
            "abuse@${config.networking.fqdn}"
            "admin@${config.networking.fqdn}"
          ];
        };
      };
    };
  };
  meta = {};
}

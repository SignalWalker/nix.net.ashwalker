{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  grocy = config.services.grocy;
in {
  options = with lib; {
    services.grocy = {
      user = mkOption {
        type = types.str;
        readOnly = true;
        default = "grocy";
      };
      group = mkOption {
        type = types.str;
        default = "grocy";
      };
      package = mkOption {
        type = types.package;
        default = pkgs.grocy.overrideAttrs (prev: {
          src = grocy.src;
          meta.broken = false;
        });
      };
    };
  };
  disabledModules = [];
  imports = [];
  config = lib.mkIf true {
    nixpkgs.config.allowBroken = true;
    nixpkgs.config.packageOverrides = pkgs: {
      grocy = grocy.package;
    };
    users.users.${grocy.user} = {
      group = lib.mkForce grocy.group;
    };
    users.groups.${grocy.group} = {};
    services.phpfpm.pools.grocy = {
      user = lib.mkForce grocy.user;
      group = lib.mkForce grocy.group;
      settings."listen.group" = "nginx";
    };
    services.grocy = {
      enable = true;
      hostName = "groceries.home.${config.networking.fqdn}";
      nginx.enableSSL = true;
    };
  };
  meta = {};
}

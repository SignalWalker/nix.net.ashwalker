{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  akkoma = config.services.akkoma;
  adirs = akkoma.directories;
  adb = akkoma.database;
in {
  options.services.akkoma = with lib; {
    enable = mkEnableOption "Akkoma";
    package = mkOption {
      type = types.package;
      default =
        pkgs.pleroma.overrideAttrs (final: prev: {
        });
    };
    user = mkOption {
      type = types.str;
      default = "akkoma";
    };
    group = mkOption {
      type = types.str;
      default = "akkoma";
    };
    directories = lib.signal.mkDirectoriesOption {defaultName = "akkoma";};
    database = {
      type = mkOption {
        type = types.enum ["postgresql"];
        default = "postgresql";
      };
      user = mkOption {
        type = types.str;
        default = akkoma.user;
      };
      name = mkOption {
        type = types.str;
        default = "akkoma";
      };
    };
  };
  disabledModules = [];
  imports = [];
  config = lib.mkIf akkoma.enable (lib.mkMerge [
    {
      environment.systemPackages = with pkgs; [exiftool];
    }
    (lib.mkIf (adb.type == "postgresql") {
      services.postgresql = {
        ensureDatabases = [adb.name];
        ensureUsers = [
          {
            name = adb.user;
            ensurePermissions = {
              "DATABASE \"${adb.name}\"" = "ALL PRIVILEGES";
            };
          }
        ];
      };
    })
  ]);
  meta = {};
}

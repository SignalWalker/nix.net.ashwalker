{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
in {
  mkDirectoriesOption = {defaultName ? null}:
    lib.mkOption {
      type = lib.signal.types.directories {inherit defaultName;};
      default = {};
    };
  types.directories = {defaultName ? null}:
    lib.types.submoduleWith {
      modules = [
        ({
          config,
          lib,
          ...
        }: {
          options = with lib; let
            mkDirOption = dirBase:
              mkOption {
                type = types.str;
                readOnly = true;
                default = "${dirBase}/${config.name}";
              };
          in {
            name = mkOption ({
                type = types.str;
              }
              // (
                if defaultName != null
                then {default = defaultName;}
                else {}
              ));
            runtime = mkDirOption "/run";
            state = mkDirOption "/var/lib";
            cache = mkDirOption "/var/cache";
            logs = mkDirOption "/var/log";
            configuration = mkDirOption "/etc";
          };
        })
      ];
    };
}

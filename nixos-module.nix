{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
in {
  options.ashwalker = with lib; {
    favicon = mkOption {
      type = types.path;
      default = config.services."ashwalker-net".favicon;
      readOnly = true;
    };
  };
  disabledModules = [];
  imports = lib.signal.fs.path.listFilePaths ./src;
  config = {};
  meta = {};
}

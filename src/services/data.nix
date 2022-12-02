{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  data = config.data.web;
in {
  options.data.web = with lib; {
    directory = mkOption {
      type = types.path;
      readOnly = true;
      default = ../../resources;
    };
    icons = mkOption {
      type = types.attrsOf (types.either types.path types.string);
      default = {};
    };
  };
  disabledModules = [];
  imports = [];
  config = {
    data.web = {
      icons = {
        ico = ../../resources/icons/pond.ico;
        x32 = ../../resources/icons/pond.32.png;
        x32lb = ../../resources/icons/pond.32.lb.png;
        x32nb = ../../resources/icons/pond.32.lb.png;
        x64 = ../../resources/icons/pond.64.png;
        x64lb = ../../resources/icons/pond.64.lb.png;
        x64nb = ../../resources/icons/pond.64.lb.png;
        x96 = ../../resources/icons/pond.96.png;
        x96lb = ../../resources/icons/pond.96.lb.png;
        x96nb = ../../resources/icons/pond.96.lb.png;
        x128 = ../../resources/icons/pond.128.png;
        x128lb = ../../resources/icons/pond.128.lb.png;
        x128nb = ../../resources/icons/pond.128.lb.png;
        x160 = ../../resources/icons/pond.160.png;
        x160lb = ../../resources/icons/pond.160.lb.png;
        x160nb = ../../resources/icons/pond.160.lb.png;
        x192 = ../../resources/icons/pond.192.png;
        x192lb = ../../resources/icons/pond.192.lb.png;
        x192nb = ../../resources/icons/pond.192.lb.png;
      };
    };
  };
  meta = {};
}

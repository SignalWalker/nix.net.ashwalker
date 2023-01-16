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
      default = ./data;
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
        svg = ./data/icons/pond.svg;
        ico = ./data/icons/pond.ico;
        x32 = ./data/icons/pond.32.png;
        x32lb = ./data/icons/pond.32.lb.png;
        x32nb = ./data/icons/pond.32.lb.png;
        x64 = ./data/icons/pond.64.png;
        x64lb = ./data/icons/pond.64.lb.png;
        x64nb = ./data/icons/pond.64.lb.png;
        x96 = ./data/icons/pond.96.png;
        x96lb = ./data/icons/pond.96.lb.png;
        x96nb = ./data/icons/pond.96.lb.png;
        x128 = ./data/icons/pond.128.png;
        x128lb = ./data/icons/pond.128.lb.png;
        x128nb = ./data/icons/pond.128.lb.png;
        x160 = ./data/icons/pond.160.png;
        x160lb = ./data/icons/pond.160.lb.png;
        x160nb = ./data/icons/pond.160.lb.png;
        x192 = ./data/icons/pond.192.png;
        x192lb = ./data/icons/pond.192.lb.png;
        x192nb = ./data/icons/pond.192.lb.png;
      };
    };
  };
  meta = {};
}

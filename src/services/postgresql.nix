{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      extraPlugins = with pkgs.postgresql_14.pkgs; [
      ];
    };
  };
  meta = {};
}

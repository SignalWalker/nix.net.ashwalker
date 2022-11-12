{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  domain = "src.${config.networking.fqdn}";
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    services.sourcehut = {
      enable = false;
      git.enable = true;
      hg.enable = true;
    };
  };
  meta = {};
}

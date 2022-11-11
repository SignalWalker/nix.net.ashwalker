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
    services.tailscale = {
      enable = true;
    };
    networking.firewall.checkReversePath = "loose";
  };
  meta = {};
}

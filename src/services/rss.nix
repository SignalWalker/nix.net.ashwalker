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
    services.tt-rss = {
      enable = true;
      pubSubHubbub.enable = true;
      selfUrlPath = "https://rss.${config.networking.fqdn}";
      registration = {
        enable = false;
        notifyAddress = "ash@ashwalker.net";
        maxUsers = 1;
      };
      virtualHost = "rss";
    };
  };
  meta = {};
}

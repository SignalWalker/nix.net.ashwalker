{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  irc = config.services.irc;
in {
  options = with lib; {
    services.irc = {
      enable = mkEnableOption "IRC server";
    };
  };
  disabledModules = [];
  imports = [
    ./irc/bouncer.nix
  ];
  config = lib.mkIf irc.enable {};
  meta = {};
}

{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  matrix = config.signal.services.matrix;
  discord = matrix.discord;
  bridge = config.services.matrix-appservice-discord;
  secrets = config.age.secrets;
in {
  options = with lib; {
    signal.services.matrix.discord = {
      enable = (mkEnableOption "matrix discord bridge") // {default = false;};
    };
    services.matrix-appservice-discord = {
      database = {
        user = mkOption {
          type = types.str;
          default = "matrix-appservice-discord";
        };
      };
      # user = mkOption {
      #   type = types.str;
      #   readOnly = true;
      #   default = "matrix-appservice-discord";
      # };
      # group = mkOption {
      #   type = types.str;
      #   readOnly = true;
      #   default = "matrix-appservice-discord";
      # };
    };
  };
  disabledModules = [];
  imports = [];
  config = lib.mkIf (matrix.enable && discord.enable) {
    age.secrets.matrixDiscordEnvironmentFile = {
      file = ./secrets/matrixDiscordEnvironmentFile.age;
      # owner = discord.user;
      # group = discord.group;
    };
    services.matrix-appservice-discord = {
      enable = true;
      environmentFile = secrets.matrixDiscordEnvironmentFile.path;
      port = 58448;
      serviceDependencies = ["conduit.service"];
      settings = lib.mkForce {
        domain = matrix.serverName;
        homeserverUrl = "https://${matrix.hostName}";
        room = {
          defaultVisibility = "private";
        };
      };
    };
  };
  meta = {};
}

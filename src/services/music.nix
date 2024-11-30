{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  vhost = "music.${config.networking.fqdn}";
  # funkwhale = config.services.funkwhale;
in {
  options = with lib; {};
  disabledModules = [];
  imports = [
    # ./music/funkwhale.nix
  ];
  config = {
    # services.funkwhale = {
    #   enable = false;
    #   dataDir = "/var/lib/funkwhale";
    #   hostname = "music.${config.networking.fqdn}";
    #   defaultFromEmail = "daemon@${funkwhale.hostname}";
    #   api = {
    #     mediaRoot = "${funkwhale.dataDir}/media";
    #     staticRoot = "/etc/funkwhale/static";
    #     # musicPath = "${funkwhale.dataDir}/music";
    #   };
    # };
  };
  meta = {};
}

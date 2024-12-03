{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  deluge = config.services.deluge;
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    services.deluge = {
      enable = true;
      # authFile = null; # todo
      declarative = false; # todo
      openFirewall = false;
      config = {
        listen_ports = [62086];
      };
      web = {
        enable = false; # todo
        openFirewall = false;
        port = 8112;
      };
    };

    networking.wireguard.tunneledUsers = lib.mkIf deluge.enable [
      deluge.user
    ];

    networking.firewall = lib.mkIf deluge.enable {
      allowedUDPPorts = deluge.config.listen_ports;
      allowedTCPPorts = deluge.config.listen_ports;
    };
  };
  meta = {};
}

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
    networking.nftables = {
      enable = true;
    };
    networking.firewall = {
    };
    services.fail2ban = {
      enable = true;
      maxretry = 12;
      # ignoreIP = [
      #   "127.0.0.0/8"
      #   # "10.0.0.0/8"
      #   # "172.16.0.0/12"
      #   # "192.168.0.0/16"
      #   "[::1]/128"
      # ];
      jails = {
        postfix = ''
          enabled = true
          mode = aggressive
        '';
        dovecot = ''
          enabled = true
          filter = dovecot[mode=aggressive]
          maxretry = 3
        '';
        "nginx-botsearch" = ''
          enabled = true
        '';
      };
    };
  };
  meta = {};
}

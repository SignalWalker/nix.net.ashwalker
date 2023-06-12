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
      maxretry = 6;
      ignoreIP = [
        "127.0.0.0/8"
        # "10.0.0.0/8"
        # "172.16.0.0/12"
        # "192.168.0.0/16"
        "::1"
        # ash-laptop tailscale address
        "100.68.182.67"
      ];
      bantime = "12m";
      bantime-increment = {
        enable = true;
        rndtime = "8m";
        overalljails = true;
      };
      jails = {
        postfix = ''
          enabled = true
          mode = aggressive
          maxretry = 3
          bantime = 12h
        '';
        dovecot = ''
          enabled = true
          filter = dovecot[mode=aggressive]
          maxretry = 3
          bantime = 12h
        '';
        "nginx-botsearch" = ''
          enabled = true
        '';
      };
    };
  };
  meta = {};
}

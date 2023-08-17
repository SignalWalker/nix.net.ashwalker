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
        # wg-signal
        "172.24.86.0/24"
      ];
      bantime = "12m";
      bantime-increment = {
        enable = true;
        rndtime = "8m";
        overalljails = true;
      };
      banaction = "nftables[type=multiport,blocktype=drop]";
      banaction-allports = "nftables[type=allports,blocktype=drop]";
      jails = {
        postfix = ''
          enabled = true
          mode = aggressive
          maxretry = 3
          findtime = 6h
          bantime = 12h
        '';
        dovecot = ''
          enabled = true
          filter = dovecot[mode=aggressive]
          maxretry = 3
          findtime = 6h
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

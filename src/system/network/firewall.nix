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
    # set openssh loglevel higher so fail2ban works better
    services.openssh.loglevel = "VERBOSE";
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
        dovecot = ''
          enabled = true
          filter = dovecot[mode=aggressive]
          maxretry = 3
        '';
      };
    };
  };
  meta = {};
}

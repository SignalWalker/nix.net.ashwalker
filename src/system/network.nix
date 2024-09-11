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
  imports = lib.signal.fs.path.listFilePaths ./network;
  config = {
    systemd.network.networks."eth" = {
      networkConfig.Address = ["5.161.136.2/32" "2a01:4ff:f0:b30::1/64"];
      routes = [
        {
          Gateway = "172.31.1.1";
        }
        {
          Gateway = "fe80::1";
        }
      ];
    };
  };
  meta = {};
}

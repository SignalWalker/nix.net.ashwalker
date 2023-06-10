{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  fwVersion = "1.2.7";
in {
  options = with lib; {
    services.funkwhale = {
      enable = mkEnableOption "funkwhale audio server";
      package = mkOption {
        type = types.package;
        default = pkgs.stdenv.mkDerivation {
          pname = "funkwhale";
          version = fwVersion;
          src = pkgs.fetchurl {
            url = "https://dev.funkwhale.audio/funkwhale/funkwhale/-/archive/${fwVersion}/funkwhale-${fwVersion}.tar.bz2";
            sha256 = "sha256-UnOz8S2OKtHJM/Lnx9Ud+Y6XziXCtZb9Qs6MqdfkdQU=";
          };
          installPhase = ''
            sed "s|env -S|env|g" -i front/scripts/*.sh
            mkdir $out
            cp -R ./* $out
          '';
        };
      };
      frontend = {
        package = mkOption {
          type = types.package;
          default = pkgs.stdenv.mkDerivation {
            pname = "funkwhale";
            version = fwVersion;
            src = pkgs.fetchurl {
              url = "https://dev.funkwhale.audio/funkwhale/funkwhale/-/jobs/artifacts/${fwVersion}/download?job=build_front";
              sha256 = "WheBYJOdQYmqyw0bOs10PfIz89NNc+a+3rVzs09brsc=";
            };
            installPhase = ''
              mkdir $out
              cp -R ./dist/* $out
            '';
          };
        };
      };
    };
  };
  disabledModules = [];
  imports = [];
  config = {};
  meta = {};
}

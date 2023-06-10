{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  matrix = config.signal.services.matrix;
in {
  options = with lib; {
    signal.services.matrix = {
      enable = (mkEnableOption "matrix") // {default = true;};
      hostName = mkOption {
        type = types.str;
        readOnly = true;
        default = "matrix.${config.networking.fqdn}";
      };
      wellKnownServer = mkOption {
        type = types.package;
        readOnly = true;
        default = pkgs.writeText "well-known-matrix-server" ''
          {
            "m.server": "${matrix.hostName}"
          }
        '';
      };
      wellKnownClient = mkOption {
        type = types.package;
        readOnly = true;
        default = pkgs.writeText "well-known-matrix-client" ''
          {
            "m.homeserver": {
              "base_url": "https://${matrix.hostName}"
            }
          }
        '';
      };
    };
  };
  disabledModules = [];
  imports = [];
  config = lib.mkIf config.signal.services.matrix.enable {
    services.matrix-conduit = {
      enable = true;
      settings.global = {
        server_name = config.networking.fqdn;
        allow_registration = false;
        # matrix_hostname = "matrix.${config.networking.fqdn}";
        # admin_email = "admin@matrix.${config.networking.fqdn}";
      };
    };
    networking.firewall.allowedTCPPorts = [80 443 8448];
    networking.firewall.allowedUDPPorts = [80 443 8448];
    services.nginx = {
      virtualHosts."${matrix.hostName}" = {
        forceSSL = true;
        enableACME = true;
        listen = [
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
          {
            addr = "[::]";
            port = 443;
            ssl = true;
          }
          {
            addr = "0.0.0.0";
            port = 8448;
            ssl = true;
          }
          {
            addr = "[::]";
            port = 8448;
            ssl = true;
          }
        ];
        locations."/_matrix/" = {
          proxyPass = "http://backend_conduit$request_uri";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_buffering off;
          '';
        };
        extraConfig = ''
          merge_slashes off;
        '';
      };
      virtualHosts."${config.services.matrix-conduit.settings.global.server_name}" = {
        locations."=/.well-known/matrix/server" = {
          alias = matrix.wellKnownServer;
          extraConfig = ''
            default_type application/json;
          '';
        };
        locations."=/.well-known/matrix/client" = {
          alias = matrix.wellKnownClient;
          extraConfig = ''
            default_type application/json;
            add_header Access-Control-Allow-Origin "*";
          '';
        };
      };
      upstreams."backend_conduit" = {
        servers = {
          "localhost:${toString config.services.matrix-conduit.settings.global.port}" = {};
        };
      };
    };
  };
  meta = {};
}

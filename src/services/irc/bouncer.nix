{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  bouncer = config.services.irc.bouncer;
  proxy = bouncer.reverseProxy;
  ssl = bouncer.ssl;
  irc = config.services.irc;
in {
  options = with lib; {
    services.irc.bouncer = {
      enable = (mkEnableOption "IRC bouncer") // {default = true;};
      user = mkOption {
        type = types.str;
        default = "ircbouncer";
      };
      group = mkOption {
        type = types.str;
        default = "ircbouncer";
      };
      directories = {
        state = mkOption {
          type = types.str;
          readOnly = true;
          default = "/var/lib/ircbouncer";
        };
      };
      port = {
        irc = mkOption {
          type = types.port;
          default = 56667;
        };
        http = mkOption {
          type = types.port;
          default = 56443;
        };
      };
      ssl = let
        acmeDir = config.security.acme.certs.${ssl.certName}.directory;
      in {
        certName = mkOption {
          type = types.str;
          default = proxy.hostName;
        };
        certificate = mkOption {
          type = types.str;
          readOnly = true;
          default = "${acmeDir}/fullchain.pem";
        };
        key = mkOption {
          type = types.str;
          readOnly = true;
          default = "${acmeDir}/key.pem";
        };
        trustedCertificate = mkOption {
          type = types.str;
          readOnly = true;
          default = "${acmeDir}/chain.pem";
        };
      };
      reverseProxy = {
        type = mkOption {
          type = types.nullOr (types.enum ["nginx"]);
          default = null;
        };
        hostName = mkOption {
          type = types.str;
          default = "bouncer.irc.${config.networking.fqdn}";
        };
      };
    };
  };
  disabledModules = [];
  imports = [];
  config = lib.mkIf bouncer.enable (lib.mkMerge [
    {
      users.users.${bouncer.user} = {
        inherit (bouncer) group;
        description = "IRC bouncer daemon";
        isSystemUser = true;
        home = bouncer.directories.state;
        createHome = true;
      };
      users.groups.${bouncer.group} = {};
      services.znc = {
        inherit (bouncer) enable user group;
        dataDir = bouncer.directories.state;
        mutable = true;
        useLegacyConfig = false;
        openFirewall = false;
        config = {
          LoadModule = [];
          User."admin" = {
            Admin = true;
          };
          SSLCertFile = ssl.certificate;
          SSLDHParamFile = ssl.certificate;
          SSLKeyFile = ssl.key;
        };
        extraFlags = [];
      };
      systemd.services."znc" = {
        serviceConfig = {
          StateDirectory = bouncer.directories.name;
          StateDirectoryMode = 0750;
        };
      };
    }
    (lib.mkIf (bouncer.reverseProxy.type == "nginx") {
      services.nginx = {
        upstreams."backend_znc_irc" = {
          servers = {
            "[::1]:${toString bouncer.port.irc}" = {};
          };
        };
        upstreams."backend_znc_http" = {
          servers = {
            "[::1]:${toString bouncer.port.http}" = {};
          };
        };
        virtualHosts.${proxy.hostName} = {
          enableACME = true;
          forceSSL = true;
          listen = [
            # IRC
            {
              addr = "0.0.0.0";
              ssl = true;
              port = 6667;
            }
            {
              addr = "[::]";
              ssl = true;
              port = 6667;
            }
            # HTTP
            {
              addr = "0.0.0.0";
              ssl = true;
              port = 443;
            }
            {
              addr = "[::]";
              ssl = true;
              port = 443;
            }
          ];
          # proxyPass = "[::1]:${toString bouncer.port}";
          locations."/" = {
            proxyPass = "https://backend_znc_http$request_uri";
            extraConfig = ''
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
          };
        };
      };
      services.znc.config = {
        LoadModule = ["webadmin" "adminlog"];
        TrustedProxy = ["127.0.0.1" "::1"];
        Listener = [
          {
            AllowIRC = true;
            AllowWeb = true;
            Host = "[::1]";
            IPv6 = true;
            Port = bouncer.port.http;
            SSL = true;
            URIPrefix = "/";
          }
          {
            AllowIRC = true;
            AllowWeb = false;
            Host = "[::1]";
            IPv6 = true;
            Port = bouncer.port.irc;
            SSL = true;
          }
        ];
      };
      systemd.services."znc" = {
        serviceConfig = {
          BindReadOnlyPaths = [
            ssl.certificate
            ssl.key
            ssl.trustedCertificate
          ];
        };
      };
    })
  ]);
  meta = {};
}

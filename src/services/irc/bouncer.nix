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
in {
  options = with lib; {
    services.irc.bouncer = {
      enable = mkEnableOption "IRC bouncer";
      user = mkOption {
        type = types.str;
        default = "ircbouncer";
      };
      group = mkOption {
        type = types.str;
        default = "ircbouncer";
      };
      directories = lib.signal.mkDirectoriesOption {defaultName = "ircbouncer";};
      port = mkOption {
        type = types.port;
        default = 6667;
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
    (lib.mkIf (bouncer.reverseProxy.type == "nginx") (let
      port = {
        http = 7001;
        irc = 7000;
      };
    in {
      services.nginx.virtualHosts.${proxy.hostName} = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "https://[::1]:${toString port.http}$uri";
          extraConfig = ''
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };
      services.nginx.virtualHosts."${proxy.hostName}_irc" = {
        serverName = proxy.hostName;
        useACMEHost = proxy.hostName;
        listen = [
          {
            addr = "0.0.0.0";
            ssl = true;
            inherit (bouncer) port;
          }
          {
            addr = "[::]";
            ssl = true;
            inherit (bouncer) port;
          }
        ];
        extraConfig = ''
          proxy_pass [::1]:${toString port.irc};
        '';
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
            Port = port.http;
            SSL = true;
            URIPrefix = "/";
          }
          {
            AllowIRC = true;
            AllowWeb = false;
            Host = "[::1]";
            IPv6 = true;
            Port = port.irc;
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
    }))
  ]);
  meta = {};
}

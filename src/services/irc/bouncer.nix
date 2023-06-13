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
        name = mkOption {
          type = types.str;
          default = "ircbouncer";
        };
        state = mkOption {
          type = types.str;
          readOnly = true;
          default = "/var/lib/${bouncer.directories.name}";
        };
        cache = mkOption {
          type = types.str;
          readOnly = true;
          default = "/var/cache/${bouncer.directories.name}";
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
        acmeDir = config.security.acme.certs."${ssl.certName}".directory;
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
          default = "nginx";
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
        mutable = false;
        useLegacyConfig = false;
        openFirewall = false;
        config = {
          LoadModule = [];
          User."admin" = {
            Admin = true;
          };
          SSLCertFile = "${bouncer.directories.cache}/ssl/fullchain.pem";
          SSLDHParamFile = "${bouncer.directories.cache}/ssl/fullchain.pem";
          SSLKeyFile = "${bouncer.directories.cache}/ssl/key.pem";
        };
        extraFlags = [];
      };
      systemd.services."znc-setup" = {
        requires = ["acme-finished-${proxy.hostName}.target"];
        after = ["network-online.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          CacheDirectory = bouncer.directories.name;
          CacheDirectoryMode = 0750;
          ExecStart = pkgs.writeScript "znc-setup" ''
            #! ${pkgs.runtimeShell}
            ssldir="$CACHE_DIRECTORY/ssl"
            mkdir --mode=0750 $ssldir
            cp ${ssl.certificate} $ssldir/chain.pem
            cp ${ssl.trustedCertificate} $ssldir/fullchain.pem
            cp ${ssl.key} $ssldir/key.pem
            chown -R ${bouncer.user}:${bouncer.group} $ssldir
          '';
        };
      };
      systemd.services."znc" = {
        requires = ["znc-setup.service"];
        after = ["znc-setup.service"];
        serviceConfig = {
          CacheDirectory = bouncer.directories.name;
          CacheDirectoryMode = 0750;
          StateDirectory = bouncer.directories.name;
          StateDirectoryMode = 0750;
        };
      };
    }
    (lib.mkIf (bouncer.reverseProxy.type == "nginx") {
      networking.firewall = {
        allowedTCPPorts = [80 443 6667];
        allowedUDPPorts = [80 443 6667];
      };
      services.nginx = {
        upstreams."backend_znc" = {
          servers = {
            "localhost:${toString bouncer.port.http}" = {};
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
        Listener = {
          l = {
            AllowIRC = true;
            AllowWeb = true;
            IPv4 = true;
            IPv6 = true;
            Port = bouncer.port.irc;
            SSL = true;
            URIPrefix = "/";
          };
        };
      };
      services.fail2ban.jails."znc-adminlog" = ''
        enabled = true
      '';
    })
  ]);
  meta = {};
}

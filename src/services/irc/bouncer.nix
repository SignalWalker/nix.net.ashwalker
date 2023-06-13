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
      age.secrets.ircBouncerPassword = {
        file = ./ircBouncerPassword.age;
        owner = bouncer.user;
        group = bouncer.group;
      };
      users.users.${bouncer.user} = {
        inherit (bouncer) group;
        description = "IRC bouncer daemon";
        isSystemUser = true;
        home = bouncer.directories.state;
        createHome = true;
      };
      users.groups.${bouncer.group} = {};
      nixpkgs.config.packageOverrides = pkgs: {
        znc = pkgs.znc.override {withPython = true;};
      };
      services.znc = {
        inherit (bouncer) enable user group;
        dataDir = bouncer.directories.state;
        mutable = false;
        useLegacyConfig = false;
        openFirewall = false;
        modulePackages = [
          (
            pkgs.stdenvNoCC.mkDerivation {
              name = "loadpassfile";
              src = ./loadpassfile.py;
              dontUnpack = true;
              installPhase = ''
                install -D $src $out/lib/znc/loadpassfile.py
              '';
              passthru.module_name = "loadpassfile";
            }
          )
        ];
        config = {
          LoadModule = ["imapauth mail.${config.networking.fqdn} +993 %@${config.networking.fqdn}"];
          SSLCertFile = "${bouncer.directories.cache}/ssl/fullchain.pem";
          SSLDHParamFile = "${bouncer.directories.cache}/ssl/fullchain.pem";
          SSLKeyFile = "${bouncer.directories.cache}/ssl/key.pem";
          SSLProtocols = "+SSLv3";
          User."ash" = {
            Admin = true;
            Pass = "md5#::#::#";
            # LoadModule = ["loadpassfile ${config.age.secrets.ircBouncerPassword.path}"];
          };
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
          # LoadCredential = [
          #   "chain.pem:${ssl.certificate}"
          #   "fullchain.pem:${ssl.trustedCertificate}"
          #   "key.pem:${ssl.key}"
          # ];
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
        virtualHosts."${proxy.hostName}_http" = {
          serverName = proxy.hostName;
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "https://backend_znc$request_uri";
            extraConfig = ''
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            '';
          };
        };
        virtualHosts."${proxy.hostName}_irc" = {
          serverName = proxy.hostName;
          useACMEHost = "${proxy.hostName}_http";
          listen = [
            {
              addr = "0.0.0.0";
              port = bouncer.port.irc;
              ssl = true;
            }
            {
              addr = "[::]";
              port = bouncer.port.irc;
              ssl = true;
            }
          ];
          extraConfig = ''
            proxy_pass backend_znc_irc;
          '';
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

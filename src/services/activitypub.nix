{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  vhost = "social.${config.networking.fqdn}";
  akkoma = config.services.akkoma;
  secrets = config.age.secrets;
  psql = config.services.postgresql;
in {
  options = with lib; {
    signal.services.activitypub = {
      enable = (mkEnableOption "activitypub") // {default = true;};
    };
    services.akkoma = {
      favicon = {
        ico = mkOption {
          type = types.path;
          default = config.data.web.icons.ico;
        };
        png = mkOption {
          type = types.path;
          default = config.data.web.icons.x64lb;
        };
        svg = mkOption {
          type = types.path;
          default = config.data.web.icons.svg;
        };
      };
      logo = mkOption {
        type = types.path;
        default = config.data.web.icons.x128lb;
      };
    };
  };
  disabledModules = [];
  imports = [];
  config = lib.mkIf config.signal.services.activitypub.enable {
    environment.systemPackages = with pkgs; [exiftool];
    age.secrets.activitypubDbPassword = {
      file = ./activitypub/secrets/activitypubDbPassword.age;
      owner = akkoma.user;
    };
    age.secrets.akkomaEndpointKey = {
      file = ./activitypub/secrets/endpointKey.age;
      owner = akkoma.user;
    };
    age.secrets.akkomaEndpointSalt = {
      file = ./activitypub/secrets/endpointSalt.age;
      owner = akkoma.user;
    };
    age.secrets.akkomaLiveViewSalt = {
      file = ./activitypub/secrets/liveViewSalt.age;
      owner = akkoma.user;
    };
    age.secrets.akkomaRepoKey = {
      file = ./activitypub/secrets/repoKey.age;
      owner = akkoma.user;
    };
    age.secrets.akkomaPushPublicKey = {
      file = ./activitypub/secrets/pushPublicKey.age;
      owner = akkoma.user;
    };
    age.secrets.akkomaPushPrivateKey = {
      file = ./activitypub/secrets/pushPrivateKey.age;
      owner = akkoma.user;
    };
    age.secrets.akkomaJokenKey = {
      file = ./activitypub/secrets/jokenKey.age;
      owner = akkoma.user;
    };
    services.postgresql = {
      ensureDatabases = ["akkoma"];
      ensureUsers = [
        {
          name = akkoma.user;
          ensurePermissions."DATABASE akkoma" = "ALL PRIVILEGES";
        }
      ];
    };
    services.akkoma = {
      enable = true;
      package = pkgs.akkoma.override {inherit (akkoma) src;}; # option defined in flake.nix
      initDb = {
        enable = false;
      };
      config = {
        ":pleroma" = {
          ":instance" = {
            name = "Signal Garden";
            email = "admin@${vhost}";
            notify_email = "daemon@${vhost}";
            description = "Ash Walker's personal Akkoma instance";
            registrations_open = false;
            invites_enabled = true;
            federating = true;
            federation_incoming_replies_max_depth = null;
            allow_relay = true;
            safe_dm_mentions = true;
            external_user_synchronization = true;
            cleanup_attachments = true;
          };
          ":media_proxy" = {
            enabled = false;
            redirect_on_failure = true;
          };
          "Pleroma.Repo" = {
            adapter = "Ecto.Adapters.Postgres";
            # username = akkoma.user;
            database = "akkoma";
            # hostname = "localhost";
            # password = {_secret = secrets.activitypubDbPassword.path;};
            socket_dir = "/run/postgresql";
            port = psql.port;
          };
          "Pleroma.Web.Endpoint" = {
            secret_key_base = {_secret = secrets.akkomaEndpointKey.path;};
            signing_salt = {_secret = secrets.akkomaEndpointSalt.path;};
            live_view.signing_salt = {_secret = secrets.akkomaLiveViewSalt.path;};
            url = {
              host = vhost;
              scheme = "https";
              port = 443;
            };
            http = {
              ip = "127.0.0.1";
              port = 4000;
            };
          };
          "Pleroma.Web.WebFinger" = {
            domain = config.networking.fqdn;
          };
        };
        ":web_push_encryption" = {
          ":vapid_details" = {
            private_key = {_secret = secrets.akkomaPushPrivateKey.path;};
            public_key = {_secret = secrets.akkomaPushPublicKey.path;};
          };
        };
        ":joken" = {
          ":default_signer" = {_secret = secrets.akkomaJokenKey.path;};
        };
      };
      extraStatic = let
        mkFile = src: name:
          pkgs.stdenvNoCC.mkDerivation {
            inherit name src;
            dontUnpack = true;
            installPhase = ''
              cp $src $out
            '';
          };
      in {
        "favicon.ico" = mkFile akkoma.favicon.ico "favicon.ico";
        "favicon.png" = mkFile akkoma.favicon.png "favicon.png";
        "favicon.svg" = mkFile akkoma.favicon.svg "favicon.svg";
      };
      nginx = null; # doing this manually
    };

    services.nginx = {
      upstreams."phoenix" = {
        extraConfig = ''
          server 127.0.0.1:4000 max_fails=5 fail_timeout=60s;
        '';
      };
      virtualHosts.${config.networking.fqdn} = {
        locations."=/.well-known/host-meta" = {
          return = "301 https://${vhost}$request_uri";
        };
      };
      virtualHosts."${vhost}" = {
        http2 = true;
        enableACME = config.networking.domain != "local";
        forceSSL = config.networking.domain != "local";
        extraConfig = ''
          client_max_body_size 16m;
          ignore_invalid_headers off;

          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

          access_log /var/log/nginx/akkoma-access.log combined;
        '';
        locations."/" = {
          recommendedProxySettings = false;
          proxyPass = "http://phoenix";
          extraConfig = ''
            etag on;
            gzip on;

            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'POST, PUT, DELETE, GET, PATCH, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, Idempotency-Key' always;
            add_header 'Access-Control-Expose-Headers' 'Link, X-RateLimit-Reset, X-RateLimit-Limit, X-RateLimit-Remaining, X-Request-Id' always;
            if ($request_method = OPTIONS) {
            	return 204;
            }
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Permitted-Cross-Domain-Policies none;
            add_header X-Frame-Options DENY;
            add_header X-Content-Type-Options nosniff;
            add_header Referrer-Policy same-origin;
            add_header X-Download-Options noopen;
          '';
        };
      };
    };
  };
  meta = {};
}

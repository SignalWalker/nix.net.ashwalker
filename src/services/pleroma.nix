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
    environment.systemPackages = with pkgs; [exiftool];
    services.postgresql = {
      ensureDatabases = ["pleroma"];
      ensureUsers = [
        {
          name = config.services.pleroma.user;
          ensurePermissions = {
            "DATABASE \"pleroma\"" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    services.pleroma = {
      enable = true;
      configs = [
        ''
          import Config

          config :pleroma, Pleroma.Web.Endpoint,
          	url: [host: "social.${config.networking.fqdn}", scheme: "https", port: 443],
            	http: [ip: {127, 0, 0, 1}, port: 4000]

          config :pleroma :instance,
          	name: "social.${config.networking.fqdn}",
          	email: "ash@ashwalker.net",
          	notify_email: "daemon@social.${config.networking.fqdn}",
          	limit: 5000,
          	registrations_open: false

          config :pleroma, :media_proxy,
          	enabled: false,
              redirect_on_failure: true

          config :pleroma, Pleroma.Repo,
          	adapter: Ecto.Adapters.Postgres,
          	username: "${config.services.pleroma.user}",
          	database: "pleroma",
          	hostname: "localhost"

          config :web_push_encryption, :vapid_details,
          	subject: "mailto:ash@ashwalker.net"

          config :pleroma, :database, rum_enabled: false
          config :pleroma, :instance, static_dir: "${config.services.pleroma.stateDir}/static"
          config :pleroma, Pleroma.Uploaders.Local, uploads: "${config.services.pleroma.stateDir}/uploads"

          config :pleroma, configurable_from_database: true

          config :pleroma, Pleroma.Upload, filters: [Pleroma.Upload.Filter.Exiftool]
        ''
      ];
    };
    services.nginx = {
      upstreams."phoenix" = {
        extraConfig = ''
          server 127.0.0.1:4000 max_fails=5 fail_timeout=60s
        '';
      };
      virtualHosts."social.${config.networking.fqdn}" = {
        http2 = true;
        enableACME = true;
        forceSSL = true;
        extraConfig = ''
          client_max_body_size 16m;
          ignore_invalid_headers off;

          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
        locations."/" = {
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

                     proxy_cache					pleroma_media_cache;
                     proxy_cache_key				$host$uri$is_args$args$slice_range;
                     proxy_set_header			Range $slice_range;
                     proxy_cache_valid			200 206 301 304 1h;
                     proxy_cache_lock			on;
                     proxy_ignore_client_abort	on;
                     proxy_buffering				on;
                     chunked_transfer_encoding	on;
                     slice						1m;
          '';
        };
      };
    };
  };
  meta = {};
}

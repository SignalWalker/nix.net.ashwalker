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
    services.pleroma = {
      enable = true;
    };
    services.nginx = {
	  upstreams."phoenix" = {
	    extraConfig = ''
			server 127.0.0.1:4000 max_fails=5 fail_timeout=60s
		'';
	  };
      virtualHosts."social.${config.networking.fqdn}" = {
        enableACME = true;
        addSSL = true;
        forceSSL = true;
		extraConfig = ''
			pgzip_vary on;
			gzip_proxied any;
			gzip_comp_level 6;
			gzip_buffers 16 8k;
			gzip_http_version 1.1;
			gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/activity+json application/atom+xml;

			client_max_body_size 16m;
			ignore_invalid_headers off;

			proxy_http_version 1.1;
			proxy_set_header Upgrade $http_upgrade;
			proxy_set_header Connection "upgrade";
			proxy_set_header Host $http_host;
			proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		'';
        locations."/" = {
        	proxyPass = "http://phoenix";
        };
        locations."~ ^/(media|proxy)" = {
        	proxyPass = "http://phoenix";
        	extraConfig = ''
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

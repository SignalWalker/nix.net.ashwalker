{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  nginx = config.services.nginx;
in {
  options = with lib; {
  };
  disabledModules = [];
  imports = [];
  config = {
    services.nginx = {
      enable = true;

      logError = "stderr warn";

      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedZstdSettings = true;

      recommendedOptimisation = true;

      recommendedTlsSettings = true;
      recommendedProxySettings = true;

      commonHttpConfig = let
        logFormatFields = [
          "http_host"
          "status"
          "remote_addr"
          "request_uri"
          "http_user_agent"
          "body_bytes_sent"
          "bytes_sent"
          "msec"
          "request_length"
          "request_method"
          "server_port"
          "server_protocol"
          "ssl_protocol"
          "upstream_response_time"
          "upstream_addr"
          "upstream_connect_time"
        ];
        logFormatStr = std.concatStringsSep ",'\n" (map (field: "'\"${field}\":\"\$${field}\"") logFormatFields);
      in ''
        map $status$http_host $not_caught_by_agent_list {
          ~^444 0;
          default 1;
        }

        map $not_caught_by_agent_list$http_host$request_uri $not_ignored {
          ~^0 0;
          ~^1matrix.ashwalker.net 0;
          1ashwalker.net/.well-known/matrix/server 0;
          1ashwalker.net/.well-known/matrix/client 0;
          default 1;
        }

        map $not_ignored$remote_addr $should_log {
          ~^0 0;
          1172.24.86.3 0;
          1fd24:fad3:8246::3 0;
          default 1;
        }

        log_format logger_json_log escape=json '{'
          ${logFormatStr}'
        '}';

        access_log /var/log/nginx/access.log logger_json_log if=$should_log;
      '';
    };
    networking.firewall.allowedTCPPorts = [80 443];
  };
  meta = {};
}

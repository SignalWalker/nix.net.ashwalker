{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  com = config.services.comentario;
  domain = "comments.ashwalker.net";
in {
  options = with lib; {};
  config = {
    age.secrets.comentario = {
      file = ./comments/comentario.age;
      owner = com.user;
      group = com.group;
    };
    services.comentario = {
      enable = true;
      settings = {
        PORT = 47320;
        BASE_URL = "https://${domain}";
        SECRETS_FILE = config.age.secrets.comentario.path;
      };
      virtualHost = {
        inherit domain;
        nginx = {
          enable = true;
        };
      };
    };
    services.nginx.virtualHost.${com.virtualHost.domain} = {
      enableACME = true;
      forceSSL = true;
    };
  };
  meta = {};
}

{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  vhost = "wiki.${config.networking.fqdn}";
  wiki = config.services.mediawiki;
  phpfpm = config.services.phpfpm.pools.mediawiki;
in {
  options = with lib; {
    signal.services.wiki = {
      enable = (mkEnableOption "wiki") // {default = false;};
    };
  };
  disabledModules = [];
  imports = [
    ./wiki/mediawiki.nix
  ];
  config = lib.mkIf config.signal.services.wiki.enable {
    age.secrets.wikiAdminPassword = {
      file = ./wiki/wikiAdminPassword.age;
      owner = wiki.user;
      group = wiki.group;
    };
    age.secrets.wikiSecrets = {
      file = ./wiki/wikiSecrets.age;
      owner = wiki.user;
      group = wiki.group;
    };
    services.mediawiki = {
      enableSignal = true;
      name = "SignalWiki";
      passwordFile = config.age.secrets.wikiAdminPassword.path;
      secretsFile = config.age.secrets.wikiSecrets.path;
      enableUploads = true;
      database = {
        type = "mysql";
      };
      reverseProxy = {
        type = "nginx";
        hostName = vhost;
      };
      settings = {
        wgArticlePath = "/wiki/$1";
        wgServer = "//${wiki.reverseProxy.hostName}";
        wgCanonicalServer = "https:${wiki.settings.wgServer}";
        wgCapitalLinks = false;
        wgDefaultSkin = "timeless";
        wgAllowDisplayTitle = true;
        wgRestrictDisplayTitle = false;
        # wgRightsPage = "";
        # wgRightsUrl = "https://creativecommons.org/licenses/by-nc-sa/4.0/";
        # wgRightsText = "Creative Commons Attribution-NonCommercial-ShareAlike";
        # wgRightsIcon = "${wiki.settings.wgResourceBasePath}/resources/assets/licenses/cc-by-nc-sa.png";
        # wgEnableEmail = false;
        # wgPingback = true;
      };
      extraSettingsPre = let
        nsPublic = toString 3000;
        nsPublicTalk = toString 3001;
      in ''
        $wgGroupPermissions['*']['createaccount'] = false;
        $wgGroupPermissions['*']['edit'] = false;
        $wgGroupPermissions['*']['read'] = false;

        $wgExtraNamespaces[${nsPublic}] = "Public";
        $wgExtraNamespaces[${nsPublicTalk}] = "Public_Talk";
        $wgWhitelistRead = ["Main Page", "Category:Public", "User:Ash"];
        $wgWhitelistReadRegexp = [ "/Public:/", "/Prompt [0-9]+/" ];

        $wgLogos = [
          'icon' => "/favicon.svg",
          '1x' => "/favicon.svg"
        ];

        $wgPFEnableStringFunctions = TRUE;
      '';
      extensions = {
        ParserFunctions = null;
        CSS = inputs.mediawiki-css;
      };
    };
    services.nginx.virtualHosts.${wiki.reverseProxy.hostName} = {
      enableACME = config.networking.domain != "local";
      forceSSL = config.networking.domain != "local";
      locations."/static/" = {
        alias = config.data.web.directory;
      };
      locations."=/favicon.svg" = {
        alias = config.data.web.icons.svg;
        extraConfig = ''
          add_header Cache-Control "public";
          expires 7d;
        '';
      };
    };
  };
  meta = {};
}

{
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
        wgRightsPage = "";
        wgRightsUrl = "https://creativecommons.org/licenses/by-nc-sa/4.0/";
        wgRightsText = "Creative Commons Attribution-NonCommercial-ShareAlike";
        wgRightsIcon = "${wiki.settings.wgResourceBasePath}/resources/assets/licenses/cc-by-nc-sa.png";
        wgLogos = let
          up = wiki.uploadsDirName;
        in {
          "icon" = "/${up}/pond_icon.png";
          "1x" = "/${up}/pond_x1.png";
          "1.5x" = "/${up}/pond_x1_5.png";
          "2x" = "/${up}/pond_x2.png";
        };
        wgEnableEmail = false;
        wgPingback = true;
      };
      extraSettingsPre = ''
        $wgGroupPermissions['*']['createaccount'] = false;
        $wgGroupPermissions['*']['edit'] = false;
        $wgGroupPermissions['*']['read'] = false;

        define("NS_PUBLIC", 3000);
        define("NS_PUBLIC_TALK", 3001);
        $wgExtraNamespaces[NS_PUBLIC] = "Public";
        $wgExtraNamespaces[NS_PUBLIC_TALK] = "Public_Talk";
        $wgWhitelistRead = ["Main Page", "Category:Public", "User:Ash"];
        $wgWhitelistReadRegexp = [ "/Public:/", "/Prompt [0-9]+/" ];

        $wgPFEnableStringFunctions = TRUE;
      '';
      extensions = {
        ParserFunctions = null;
      };
    };
    services.nginx.virtualHosts.${wiki.reverseProxy.hostName} = {
      enableACME = true;
      forceSSL = true;
      locations."= /favicon.ico" = lib.mkForce {
        proxyPass = "https://ashwalker.net/favicon.ico";
        extraConfig = ''
          add_header Cache-Control "public";
          expires 7d;
        '';
      };
    };
  };
  meta = {};
}

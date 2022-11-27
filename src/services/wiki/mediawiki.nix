{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  wiki = config.services.mediawiki;
in {
  options.services.mediawiki = with lib; {
    enableSignal = mkEnableOption "improved configuration";
    scriptsDir = mkOption {
      type = types.str;
      readOnly = true;
      default = "${wiki.package}/share/mediawiki/maintenance";
    };
    scripts = mkOption {
      type = types.package;
      readOnly = true;
      default =
        pkgs.runCommand "mediawiki-scripts" {
          nativeBuildInputs = [pkgs.makeWrapper];
          preferLocalBuild = true;
        } ''
          mkdir -p $out/bin
          for i in changePassword.php createAndPromote.php userOptions.php edit.php nukePage.php update.php; do
            makeWrapper ${pkgs.php}/bin/php $out/bin/mediawiki-$(basename $i .php) \
          	--set MEDIAWIKI_CONFIG ${wiki.settingsFile} \
          	--add-flags ${wiki.scriptsDir}/$i
          done
        '';
    };
    user = mkOption {
      type = types.str;
      default = "mediawiki";
    };
    group = mkOption {
      type = types.str;
      default = "mediawiki";
    };
    stateDirName = mkOption {
      type = types.str;
      default = "mediawiki";
    };
    cacheDirName = mkOption {
      type = types.str;
      default = "mediawiki";
    };
    stateDir = mkOption {
      type = types.str;
      readOnly = true;
      default = "/var/lib/${wiki.stateDirName}";
    };
    cacheDir = mkOption {
      type = types.str;
      readOnly = true;
      default = "/var/cache/${wiki.cacheDirName}";
    };
    secretKey = mkOption {
      type = types.str;
      readOnly = true;
      default = "${wiki.stateDir}/secret.key";
    };
    extraSettingsPre = mkOption {
      type = types.lines;
      default = "";
    };
    settings = mkOption {
      type = types.submoduleWith {
        modules = [
          ({
            config,
            lib,
            ...
          }: {
            freeformType = with lib; types.attrsOf (types.oneOf (with types; [string path attrs bool float int list]));
            options = with lib; {
              wgServer = mkOption {
                type = types.str;
              };
              wgCanonicalServer = mkOption {
                type = types.str;
                default = "http://${config.wgServer}";
              };
              wgSitename = mkOption {
                type = types.str;
                default = wiki.name;
                readOnly = true;
              };
              wgMetaNamespace = mkOption {
                type = types.str;
                default = config.wgSitename;
              };
              wgUsePathInfo = mkOption {
                type = types.bool;
                default = true;
              };
              wgScriptPath = mkOption {
                type = types.str;
                default = "";
                description = "Base path relative to the FQDN of the MediaWiki installation. Other paths are defined relative to this.";
              };
              wgScript = mkOption {
                type = types.str;
                default = "${config.wgScriptPath}/index.php";
              };
              wgArticlePath = mkOption {
                type = types.str;
                default =
                  if config.wgUsePathInfo
                  then "${config.wgScript}/$1"
                  else "${config.wgScript}?title=$1";
              };
              wgDBtype = mkOption {
                type = types.enum ["mysql" "postgres" "sqlite"];
                default = wiki.database.type;
                readOnly = true;
              };
              wgDBserver = mkOption {
                type = types.str;
                default = "${wiki.database.host}:${
                  if wiki.database.socket != null
                  then wiki.database.socket
                  else toString wiki.database.port
                }";
                readOnly = true;
              };
              wgDBname = mkOption {
                type = types.str;
                default = wiki.database.name;
                readOnly = true;
              };
              wgDBuser = mkOption {
                type = types.str;
                default = wiki.database.user;
                readOnly = true;
              };
              wgEnableUploads = mkOption {
                type = types.bool;
                default = wiki.uploadsDir != null;
                readOnly = true;
              };
              wgUploadDirectory = mkOption {
                type = types.str;
                default = wiki.uploadsDir;
                readOnly = true;
              };
              wgUseImageMagick = mkOption {
                type = types.bool;
                default = true;
                readOnly = true;
              };
              wgImageMagickConvertCommand = mkOption {
                type = types.str;
                default = "${pkgs.imagemagick}/bin/convert";
                readOnly = true;
              };
              wgShellLocale = mkOption {
                type = types.str;
                default = "C.UTF-8";
                readOnly = true;
              };
              wgCacheDirectory = mkOption {
                type = types.str;
                default = wiki.cacheDir;
                readOnly = true;
              };
              wgDiff = mkOption {
                type = types.str;
                default = "${pkgs.diffutils}/bin/diff";
              };
              wgDiff3 = mkOption {
                type = types.str;
                default = "${pkgs.diffutils}/bin/diff3";
              };
              __toString = mkOption {
                type = types.anything;
                default = self: let
                  getType = val:
                    if isString val
                    then "string"
                    else if isPath val
                    then "path"
                    else if isAttrs val
                    then "attrs"
                    else if isBool val
                    then "bool"
                    else if isFunction val
                    then "function"
                    else if isFloat val
                    then "float"
                    else if isInt val
                    then "int"
                    else if isList val
                    then "list"
                    else if isNull val
                    then "null"
                    else "unknown";
                  subMap = {
                    "string" = val: "\"${val}\"";
                    "path" = val: "\"${val}\"";
                    __default = val: toString val;
                  };
                  typeMap = {
                    "attrs" = key: val: concatMapStringsSep "\n" (skey: "\$${key}['${skey}'] = ${(subMap.${getType val.${skey}} or subMap.__default) val};") (attrNames val);
                    __default = key: val: "\$${key} = ${(subMap.${getType val} or subMap.__default) val};";
                  };
                  keyMap = {
                    __toString = key: val: "";
                    __default = key: val: (typeMap.${getType val} or typeMap.__default) key val;
                  };
                in
                  concatMapStringsSep "\n" (key: (keyMap.${key} or keyMap.__default) key self.${key}) (attrNames self);
                readOnly = true;
              };
            };
          })
        ];
      };
    };
    extraSettingsPost = mkOption {
      type = types.lines;
      default = "";
    };
    settingsFile = mkOption {
      type = types.path;
      default = pkgs.writeText "LocalSettings.php" (concatStringsSep "\n" ([
        "<?php"
        wiki.extraSettingsPre
        (toString wiki.settings)
        wiki.extraSettingsPost
	  ]
	  ++ (std.mapAttrsToList (k: v: "wfLoadSkin('${k}', '${v}');") wiki.skins)
      ++ (std.mapAttrsToList (k: v: "wfLoadExtensions('${k}'${
            if v == null
            then ""
            else ", '${v}'"
          });")
          wiki.extensions)
      ));
      readOnly = true;
    };
    phpfpm = {
      listenOwner = mkOption {
        type = types.str;
        default = config.services.mediawiki.user;
      };
      listenGroup = mkOption {
        type = types.str;
        default = config.services.mediawiki.group;
      };
      extraSettings = mkOption {
        type = with types; attrsOf (oneOf [str int bool]);
        default = {};
      };
    };
    reverseProxy = {
      type = mkOption {
        type = types.enum [null "nginx" "httpd"];
        default = null;
      };
      hostName = mkOption {
        type = types.str;
      };
    };
  };
  disabledModules = [];
  imports = [];
  config = lib.mkIf wiki.enableSignal (lib.mkMerge [
    {
      environment.systemPackages = [wiki.scripts];
      services.mediawiki = {
        enable = lib.mkForce false;
        extraSettingsPre = ''
          if ( !defined( 'MEDIAWIKI' ) ) {
          	exit;
          }
        '';
        extraSettingsPost = ''
          $wgDBpassword = file_get_contents("${wiki.database.passwordFile}");
          $wgSecretKey = file_get_contents("${wiki.secretKey}");
        '';
      };
      users.users.${wiki.user} = {
        inherit (wiki) group;
        isSystemUser = true;
      };
      users.groups.${wiki.group} = {};
      services.phpfpm.pools.mediawiki = {
        inherit (wiki) user group;
        phpEnv.MEDIAWIKI_CONFIG = toString wiki.settingsFile;
		settings = wiki.phpfpm.extraSettings // {
			"listen.owner" = wiki.phpfpm.listenOwner;
			"listen.group" = wiki.phpfpm.listenGroup;
		};
      };
      systemd.services.mediawiki-init = let
        db = wiki.database;
      in {
        wantedBy = ["multi-user.target"];
        before = ["phpfpm-mediawiki.service"];
        after = ["postgresql.service"];
        script = ''
          if ! test -e "${wiki.secretKey}"; then
            tr -dc A-Za-z0-9 </dev/urandom 2>/dev/null | head -c 64 > ${wiki.stateDir}/secret.key
          fi

          echo "exit( wfGetDB( DB_MASTER )->tableExists( 'user' ) ? 1 : 0 );" | \
            ${pkgs.php}/bin/php ${wiki.scriptsDir}/eval.php --conf ${wiki.settingsFile} && \
                  ${pkgs.php}/bin/php ${wiki.scriptsDir}/install.php \
                  	--confpath /tmp \
                  	--scriptpath / \
                  	--dbserver ${db.host}${std.optionalString (db.socket != null) ":${db.socket}"} \
                  	--dbport ${toString db.port} \
                  	--dbname ${db.name} \
                  	${std.optionalString (db.tablePrefix != null) "--dbprefix ${db.tablePrefix}"} \
                  	--dbuser ${db.user} \
                  	${std.optionalString (db.passwordFile != null) "--dbpassfile ${db.passwordFile}"} \
                  	--passfile ${wiki.passwordFile} \
                  	--dbtype ${db.type} \
                  	${wiki.name} \
                  	admin

          ${pkgs.php}/bin/php ${wiki.scriptsDir}/update.php --conf ${wiki.settingsFile} --quick
        '';
        serviceConfig = {
          Type = "oneshot";
          User = wiki.user;
          Group = wiki.group;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "full";
          CacheDirectory = [wiki.cacheDirName];
          CacheDirectoryMode = 0700;
          StateDirectory = [wiki.stateDirName];
          StateDirectoryMode = 0700;
        };
      };
    }
    (lib.mkIf (wiki.database.type == "postgres") {
      services.postgresql = {
        ensureUsers = [
          {
            name = wiki.database.user;
            ensurePermissions = {"DATABASE ${wiki.database.name}" = "ALL PRIVILEGES";};
          }
        ];
        ensureDatabases = [wiki.database.name];
      };
      services.mediawiki = {
        database.port = lib.mkDefault config.services.postgresql.port;
      };
    })
    (lib.mkIf (wiki.reverseProxy.type == "nginx") {
      services.nginx = let
        phpfpm = config.services.phpfpm.pools.mediawiki;
      in {
        virtualHosts.${wiki.reverseProxy.hostName} = {
          root = "${wiki.package}/share/mediawiki";
          locations."/" = {
            tryFiles = "$uri $uri/ @rewrite";
          };
          locations."@rewrite" = {
            extraConfig = ''
              rewrite ^/(.*)$ /index.php?title=$1&$args;
            '';
          };
          locations."^~ /maintenance/" = {
            return = "403";
          };
          locations."/rest.php" = {
            tryFiles = "$uri $uri/ /rest.php?$args";
          };
          locations."~ \\.php$" = {
            fastcgiParams."SCRIPT_FILENAME" = "$request_filename";
            extraConfig = ''
              fastcgi_pass unix:${phpfpm.socket};
            '';
          };
          locations."~* \\.(js|css|png|jpg|jpeg|gif|ico)$" = {
            tryFiles = "$uri /index.php";
            extraConfig = ''
              expires max;
              log_not_found off;
            '';
          };
          locations."/_.gif" = {
            extraConfig = ''
              expires max;
              empty_gif;
            '';
          };
          locations."^~ /cache/" = {
            extraConfig = ''
              deny all;
            '';
          };
          locations."/dumps" = {
            root = "/var/lib/mediawiki/local";
            extraConfig = ''
              autoindex on;
            '';
          };
        };
      };
    })
  ]);
  meta = {};
}

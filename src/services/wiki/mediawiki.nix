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
	enableUploads = mkEnableOption "media uploads";
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
          for i in changePassword.php createAndPromote.php userOptions.php edit.php nukePage.php update.php install.php; do
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
	uploadsDirName = mkOption {
	  type = types.str;
	  default = "uploads";
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
                readOnly = true;
              };
			  wgDBport = mkOption {
			  	type = types.port;
				default = config.services.postgresql.port; # this option is only used if wgDBtype is "postgres"
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
                default = wiki.enableUploads;
                readOnly = true;
              };
              wgUploadDirectory = mkOption {
                type = types.str;
                default = wiki.uploadsDir;
                readOnly = true;
              };
			  wgUploadPath = mkOption {
			  	type = types.str;
				default = "${config.wgScriptPath}/${wiki.uploadsDirName}";
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
					"bool" = val: if val then "true" else "false";
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
	  ++ (std.mapAttrsToList (k: v: "wfLoadSkin('${k}', '${v}/skin.json');") wiki.skins)
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
		database = {
			host = lib.mkDefault "127.0.0.1";
		};
        extraSettingsPre = ''
          if ( !defined( 'MEDIAWIKI' ) ) {
          	exit;
          }
        '';
        extraSettingsPost = ''
          $wgSecretKey = file_get_contents('${wiki.secretKey}');
		  ${std.optionalString (wiki.database.passwordFile != null) "$wgDBpassword = file_get_contents('${wiki.database.passwordFile}');"}
        '';
		skins = let
			skinsDir = "${wiki.package}/share/mediawiki/skins";
		in {
		  MonoBook = "${skinsDir}/MonoBook";
		  Timeless = "${skinsDir}/Timeless";
		  Vector = "${skinsDir}/Vector";
		  MinervaNeue = "${skinsDir}/MinervaNeue";
		};
		uploadsDir = lib.mkDefault "${wiki.stateDir}/${wiki.uploadsDirName}";
      };
      users.users.${wiki.user} = {
        inherit (wiki) group;
        isSystemUser = true;
      };
      users.groups.${wiki.group} = {};
      services.phpfpm.pools.mediawiki = {
        inherit (wiki) user group;
        phpEnv.MEDIAWIKI_CONFIG = toString wiki.settingsFile;
		settings = {
			"pm" = "dynamic";
        	"pm.max_children" = 32;
        	"pm.start_servers" = 2;
        	"pm.min_spare_servers" = 2;
        	"pm.max_spare_servers" = 4;
        	"pm.max_requests" = 500;
			"catch_workers_output" = "yes";
			"listen.owner" = wiki.phpfpm.listenOwner;
			"listen.group" = wiki.phpfpm.listenGroup;
		};
      };
      systemd.services.mediawiki-init = let
        db = wiki.database;
      in {
        wantedBy = ["multi-user.target"];
        before = ["phpfpm-mediawiki.service"];
        script = let
			php = "${pkgs.php}/bin/php";
			scripts = wiki.scriptsDir;
			settings = wiki.settingsFile;
		in ''
          if ! test -e "${wiki.secretKey}"; then
		  	echo "Secret key not found. Generating a new one..."
            tr -dc A-Za-z0-9 </dev/urandom 2>/dev/null | head -c 64 > ${wiki.secretKey}
          fi
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
		# authentication = let db = wiki.database; in ''
		# host	${db.name}	${db.user}	samehost	password
		# '';
      };
      services.mediawiki = {
        database.port = lib.mkDefault config.services.postgresql.port;
		settings.wgDBserver = "/run/postgresql";
		settings.wgDBport = config.services.postgresql.port;
      };
	  systemd.services.mediawiki-init.after = ["postgresql.service"];
    })
    (lib.mkIf (wiki.reverseProxy.type == "nginx") {
	  services.mediawiki.phpfpm.listenGroup = config.services.nginx.group;
      services.nginx = let
        pool = config.services.phpfpm.pools.mediawiki;
		wg = wiki.settings;
		sPath = wg.wgScriptPath;
      in {
        virtualHosts.${wiki.reverseProxy.hostName} = {
          root = "${wiki.package}/share/mediawiki";
		  locations."~ ^${sPath}/(index|load|api|thumb|opensearch_desc|rest|img_auth)\.php$" = {
		  	fastcgiParams = {
				SCRIPT_FILENAME = "$document_root$fastcgi_script_name";
			};
			extraConfig = ''
				fastcgi_pass unix:${pool.socket};
			'';
		  };
		  locations."${sPath}/${wiki.uploadsDirName}" = {
		  	# separate location for uploads so php execution won't apply
		  };
		  locations."${sPath}/${wiki.uploadsDirName}/deleted".extraConfig = "deny all;";
		  locations."~ ^${sPath}/resources/(assets|lib|src)" = {
		  	tryFiles = "$uri 404";
			extraConfig = ''
			add_header Cache-Control "public";
			expires 7d;
			'';
		  };
		  locations."~ ^${sPath}/(skins|extensions)/.+\.(css|js|gif|jpg|jpeg|png|svg|wasm)$" = {
		  	tryFiles = "$uri 404";
			extraConfig = ''
			add_header Cache-Control "public";
			expires 7d;
			'';
		  };
		  locations."= /favicon.ico" = {
			alias = "${sPath}/images/6/64/Favicon.ico";
			extraConfig = ''
			add_header Cache-Control "public";
			expires 7d;
			'';
		  };
		  locations."~ ^${sPath}/(COPYING|CREDITS)$".extraConfig = "default_type text/plain;";
		  # for the installer/updater
		  locations."${sPath}/mw-config/" = {
		  	extraConfig = ''
			location ~ \.php$ {
				fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
				fastcgi_pass unix:${pool.socket};
			}
			'';
		  };
		  locations."${sPath}/rest.php/" = {
		  	tryFiles = "$uri $uri/ ${sPath}/rest.php?$query_string";
		  };
		  locations."/wiki/".extraConfig = "rewrite ^/wiki/(?<pagename>.*)$ ${sPath}/index.php;";
		  locations."/robots.txt" = {};
		  locations."= /".return = "301 /wiki/Main_Page";
		  locations."/".return = "404";
        };
      };
    })
  ]);
  meta = {};
}

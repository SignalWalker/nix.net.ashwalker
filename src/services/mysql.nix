{
	config,
	pkgs,
	lib,
	...
}:
with builtins; let
	std = pkgs.lib;
	mysql = config.services.mysql;
in {
	options = with lib; {};
	disabledModules = [];
	imports = [];
	config = {
		systemd.tmpfiles.rules = [
			"d '/var/log/mysql' 0750 ${mysql.user} ${mysql.group} - -"
		];
		services.mysql = {
			enable = config.signal.services.wiki.enable;
			package = pkgs.mariadb;
			settings = {
				mariadb = {
					general_log = true;
					# general_log_file = "/var/log/mysql/mariadb.log";
				};
			};
		};
	};
	meta = {};
}

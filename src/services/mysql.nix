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
		services.mysql = {
			enable = config.signal.services.wiki.enable;
			package = pkgs.mariadb;
		};
	};
	meta = {};
}

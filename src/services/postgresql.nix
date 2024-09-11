{
  config,
  pkgs,
  lib,
  ...
}:
with builtins; let
  std = pkgs.lib;
  pg = config.services.postgresql;
  pgbck = config.services.postgresqlBackup;
  shouldUpgrade = pg.package.psqlSchema != pkgs.postgresql.psqlSchema;
in {
  options = with lib; {};
  disabledModules = [];
  imports = [];
  config = {
    warnings = lib.mkIf shouldUpgrade [
      "postgresql upgrade available (${pg.package.psqlSchema} -> ${pkgs.postgresql.psqlSchema}); use `sudo upgrade-pg-cluster` to upgrade"
    ];
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      extraPlugins = ps: with ps; [];
    };
    services.postgresqlBackup = {
      enable = pg.enable;
      location = "/var/backup/postgres";
      compression = "zstd";
      compressionLevel =
        if pgbck.compression == "zstd"
        then 19
        else 9;
    };
    environment.systemPackages = lib.mkIf shouldUpgrade [
      (let
        newPg = pkgs.postgresql.withPackages pg.extraPlugins;
      in
        pkgs.writeScriptBin "upgrade-pg-cluster" ''
          set -eux
          # XXX it's perhaps advisable to stop all services that depend on postgresql
          systemctl stop postgresql

          export NEWDATA="/var/lib/postgresql/${newPg.psqlSchema}"

          export NEWBIN="${newPg}/bin"

          export OLDDATA="${pg.dataDir}"
          export OLDBIN="${pg.package}/bin"

          install -d -m 0700 -o postgres -g postgres "$NEWDATA"
          cd "$NEWDATA"
          sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

          sudo -u postgres $NEWBIN/pg_upgrade \
            --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
            --old-bindir $OLDBIN --new-bindir $NEWBIN \
            --jobs $(nproc) \
            --link \
            "$@"
        '')
    ];
  };
  meta = {};
}

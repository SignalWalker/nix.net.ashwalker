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
      package = pkgs.postgresql_16;
      enableJIT = true;
      extraPlugins = ps: with ps; [];
      settings = {
        # from https://pgtune.leopard.in.ua/
        max_connections = 20;
        shared_buffers = "512MB";
        effective_cache_size = "1536MB";
        maintenance_work_mem = "128MB";
        checkpoint_completion_target = 0.9;
        wal_buffers = "16MB";
        default_statistics_target = 100;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
        work_mem = "13107kB";
        huge_pages = false;
        min_wal_size = "1GB";
        max_wal_size = "4GB";
      };
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

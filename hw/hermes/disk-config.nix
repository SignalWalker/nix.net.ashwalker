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
    disko.devices = {
      disk = {
        primary = {
          type = "disk";
          device = "/dev/sda";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                name = "boot";
                size = "1M";
                type = "EF02";
              };
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              swap = {
                size = "8G";
                type = "8200";
                content = {
                  type = "swap";
                  randomEncryption = true;
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "rpool";
                };
              };
            };
          };
        };
      };
      zpool = {
        "rpool" = {
          type = "zpool";
          options = {
            ashift = toString 12;
          };
          rootFsOptions = {
            acltype = "posixacl";
            xattr = "sa";
            compression = "zstd";
            atime = "off";
            encryption = "on";
            keyformat = "passphrase";
            keylocation = "file:///tmp/rpool.key";
            mountpoint = "/";
          };
          # mountpoint = "/";
          postCreateHook = ''
            zfs set keylocation="prompt" "rpool"
            zfs list -t snapshot -H -o name | grep -E '^rpool@blank$' || zfs snapshot rpool@blank
          '';
          datasets = {
            "home" = {
              type = "zfs_fs";
              mountpoint = "/home";
            };
            "var" = {
              type = "zfs_fs";
              mountpoint = "/var";
            };
            "nix" = {
              type = "zfs_fs";
              mountpoint = "/nix";
            };
          };
        };
      };
    };
  };
  meta = {};
}

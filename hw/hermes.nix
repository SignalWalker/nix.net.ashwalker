{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
with builtins; let
  std = pkgs.lib;
in {
  options = with lib; {};
  disabledModules = [];
  imports =
    (lib.signal.fs.path.listFilePaths ./hermes)
    ++ [
      (modulesPath + "/profiles/qemu-guest.nix")
    ];
  config = {
    boot.initrd.availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "sd_mod" "sr_mod"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = [];
    boot.extraModulePackages = [];

    fileSystems."/" = {
      device = "rpool/nixos/root";
      fsType = "zfs";
      options = ["zfsutil" "X-mount.mkdir"];
    };

    fileSystems."/home" = {
      device = "rpool/nixos/home";
      fsType = "zfs";
      options = ["zfsutil" "X-mount.mkdir"];
    };

    fileSystems."/var/lib" = {
      device = "rpool/nixos/var/lib";
      fsType = "zfs";
      options = ["zfsutil" "X-mount.mkdir"];
    };

    fileSystems."/var/log" = {
      device = "rpool/nixos/var/log";
      fsType = "zfs";
      options = ["zfsutil" "X-mount.mkdir"];
    };

    fileSystems."/boot" = {
      device = "bpool/nixos/root";
      fsType = "zfs";
      options = ["zfsutil" "X-mount.mkdir"];
    };

    fileSystems."/boot/efi" = {
      device = "/dev/disk/by-uuid/7D6B-B145";
      fsType = "vfat";
    };

    swapDevices = [
      {device = "/dev/zvol/rpool/swap";}
    ];

    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    nixpkgs.hostPlatform = "x86_64-linux";
  };
  meta = {};
}

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
      device = "rpool";
      fsType = "zfs";
      options = ["zfsutil" "X-mount.mkdir"];
    };

    #
    # fileSystems."/home" = {
    #   device = "rpool/home";
    #   fsType = "zfs";
    #   options = ["zfsutil" "X-mount.mkdir"];
    # };
    #
    # fileSystems."/var" = {
    #   device = "rpool/var";
    #   fsType = "zfs";
    #   options = ["zfsutil" "X-mount.mkdir"];
    # };
    #
    # fileSystems."/nix" = {
    #   device = "rpool/nix";
    #   fsType = "zfs";
    #   options = ["zfsutil" "X-mount.mkdir"];
    # };
    #
    # fileSystems."/boot" = {
    #   device = "/dev/disk/by-uuid/5E2B-7B19";
    #   fsType = "vfat";
    # };
    #
    # swapDevices = [
    #   {device = "/dev/disk/by-uuid/7bd607db-4e9f-4b82-8fd1-15ad28b0ce1e";}
    # ];

    # boot.zfs.extraPools = ["rpool"];

    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    nixpkgs.hostPlatform = "x86_64-linux";
  };
  meta = {};
}

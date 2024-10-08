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
    boot.supportedFilesystems = ["zfs"];
    networking.hostId = "fb3ab582";
    boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    # boot.loader.efi.efiSysMountPoint = "/boot/efi";
    boot.loader.efi.canTouchEfiVariables = false;
    # boot.loader.generationsDir.copyKernels = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    boot.loader.grub.enable = true;
    boot.loader.grub.copyKernels = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.zfsSupport = true;
    # boot.loader.grub.extraPrepareConfig = ''
    #   mkdir -p /boot/efis
    #   for i in  /boot/efis/*; do mount $i ; done
    #
    #   mkdir -p /boot/efi
    #   mount /boot/efi
    # '';
    # boot.loader.grub.extraInstallCommands = let
    #   mktemp = "${pkgs.coreutils}/bin/mktemp";
    #   cp = "${pkgs.coreutils}/bin/cp";
    #   rm = "${pkgs.coreutils}/bin/rm";
    # in ''
    #   ESP_MIRROR=$(${mktemp} -d)
    #   ${cp} -r /boot/efi/EFI $ESP_MIRROR
    #   for i in /boot/efis/*; do
    #    ${cp} -r $ESP_MIRROR/EFI $i
    #   done
    #   ${rm} -rf $ESP_MIRROR
    # '';
    boot.loader.grub.devices = [
      "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_24508713"
    ];
  };
  meta = {};
}

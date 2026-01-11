{ _config, pkgs, ... }:
{
  # Support des systèmes de fichiers
  boot.supportedFilesystems = [
    "ntfs"
    "exfat"
    "vfat"
    "ext4"
    "btrfs"
  ];

  # Packages nécessaires
  environment.systemPackages = with pkgs; [
    ntfs3g
    exfatprogs
  ];

  # udisks2 activé SEULEMENT pour les USB
  services.udisks2.enable = true;

  # Règle udev : udisks2 ignore TOUS les disques internes (non-USB)
  services.udev.extraRules = ''
    # Ignore tous les disques SAUF les USB
    SUBSYSTEM=="block", KERNEL=="sd*", SUBSYSTEMS!="usb", ENV{UDISKS_IGNORE}="1"
    SUBSYSTEM=="block", KERNEL=="nvme*", ENV{UDISKS_IGNORE}="1"
  '';

  # Configuration des montages internes dans /mnt/
  fileSystems."/mnt/Ventoy" = {
    device = "/dev/disk/by-uuid/4E21-0000";
    fsType = "exfat";
    options = [
      "nofail"
      "rw"
      "umask=0000"
      "uid=1000"
      "gid=100"
    ];
  };

  # Crée les points de montage
  systemd.tmpfiles.rules = [
    "d /mnt/Ventoy 0755 root root -"
  ];
}

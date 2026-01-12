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

  # Configuration des montages internes dans /mnt/
  fileSystems."/mnt/Windows" = {
    device = "/dev/disk/by-uuid/90D0538CD0537804";
    fsType = "ntfs";
    options = [
      "nofail"
      "noperm"
      ];
  };

  # Crée les points de montage
  systemd.tmpfiles.rules = [
    "d /mnt/Windows 0755 root root -"
    ];
}

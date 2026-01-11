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

  # Monte tes disques INTERNES dans /mnt/

  # Exemple : Disque interne supplémentaire
  # fileSystems."/mnt/storage" = {
  #   device = "/dev/disk/by-uuid/TON-UUID";
  #   fsType = "ext4";  # ou "ntfs-3g", "exfat", etc.
  #   options = [ "nofail" ];
  # };

  # Configuration des montages
  fileSystems."/mnt/Ventoy" = {
    device = "/dev/disk/by-uuid/4E21-0000";
    fsType = "exfat";
    options = [
      "nofail"
      "rw"
      "umask=0000"
    ];
  };

  # Crée les points de montage
  systemd.tmpfiles.rules = [
    "d /mnt/Ventoy 0755 root root -"
  ];
}

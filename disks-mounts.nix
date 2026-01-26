{ _config, _pkgs, ... }:
{

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

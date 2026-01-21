{ _config, pkgs, ... }:

{

  imports = [
    # Inclut les résultats du scan matériel (drivers, partitions).
    ./hardware-configuration.nix
    ./network-mounts.nix
    ./disks-mounts.nix
  ];

  # --- BOOT ET GRAPHIQUES ---
  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "video=1920x1080@60"
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "amdgpu.dcverbose=0"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    kernelModules = [
      "ntsync"
    ];

    supportedFilesystems = [
      "ntfs"
      "exfat"
      "vfat"
      "ext4"
      "btrfs"
    ];

    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
      };

      efi.canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking.firewall.enable = false;
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Paris";
  i18n = {
    defaultLocale = "fr_FR.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "fr_FR.UTF-8";
      LC_IDENTIFICATION = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_NAME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_TELEPHONE = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
    };
  };

  nixpkgs.config.allowUnfree = true;

 services.lact.enable = true;
  hardware.amdgpu.overdrive.enable = true;

  services.xserver = {
    enable = true;
    xkb.layout = "fr";
    videoDrivers = [ "amdgpu" ];
  };

  console.keyMap = "fr";

  services.xserver.excludePackages = with pkgs; [
    xterm
  ];

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "breeze";

  extraPackages = with pkgs; [
    papirus-icon-theme
  ];

  };

 hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;  # Active automatiquement au démarrage
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Nécessaire pour les jeux 32 bits (Steam).
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
    ];
  };

 services.samba = {
    enable = true;
    openFirewall = true;
  };

  # Avahi pour la découverte mDNS/Zeroconf
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # Support NFS
  services.rpcbind.enable = true;

  # Gvfs pour l'intégration SMB/NFS dans Dolphin/KDE
  services.gvfs.enable = true;

  # --- UTILISATEUR ET PACKAGES ---
  users.users.sinsry = {
    isNormalUser = true;
    description = "Sinsry";
    extraGroups = [ "networkmanager" "wheel" ]; # Wheel permet d'utiliser sudo.

    ];
  };

  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    ntfs3g
    exfatprogs
    nvd
    rar
    libnotify
    google-chrome
    meld
    cifs-utils
    samba
    nfs-utils
    nil
    nixfmt
    psmisc
    git
    discord
    heroic
    mangohud
    goverlay
    vulkan-tools
    vlc
    mpv
    ffmpeg
    gamescope
    papirus-icon-theme
    wowup-cf
    fastfetch
    rsync
    vorta
    protonvpn-gui
    kdePackages.kate
    kdePackages.breeze-gtk
    kdePackages.partitionmanager
    kdePackages.filelight
    kdePackages.plasma-browser-integration

    (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
      [General]
      background=/etc/nixos/asset/maousse/wallpaper-sddm.png
     '')
    (pkgs.writeTextDir "etc/xdg/kdeglobals" ''
      [Icons]
      Theme=Papirus-Dark
    '')
  ];
  programs.firefox = { # Navigateur interne + config fr
    enable = true;
    languagePacks = [ "fr" ];
    preferences = {
      "intl.locale.requested" = "fr";
    };

    nativeMessagingHosts.packages = [ pkgs.kdePackages.plasma-browser-integration ]

 };

 programs.chromium = {
  enable = true;
  extraOpts = {
    "NativeMessagingHosts" = {
      "org.kde.plasma.browser_integration" = "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";
    };
  };
};

  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      user = {
        name = "Sinsry";
        email = "Sinsry@users.noreply.github.com";
      };
      credential.helper = "cache --timeout=604800";  # Cache le token 1 semaine
    };
  };


  # --- MISES À JOUR ET NETTOYAGE ---
  # Automatisation des mises à jour système à 4h du matin.
  system.autoUpgrade = {
    enable = true;
    allowReboot = false; # On ne redémarre jamais sans ton accord.
    dates = "04:00";
  };

  # Service de notification pour prévenir quand une mise à jour est prête.
  systemd.services.nixos-upgrade-notification = {
    description = "Notification de mise à jour NixOS intelligente";
    # On le lance après la mise à jour automatique
    after = [ "nixos-upgrade.service" ];
    wantedBy = [ "nixos-upgrade.service" ];

    script = ''
      # On compare l'ID de la version actuelle avec celle du lien 'system'
      # Si c'est différent, alors on notifie.
      CURRENT_GEN=$(readlink /run/current-system)
      LATEST_GEN=$(readlink /nix/var/nix/profiles/system)

      if [ "$CURRENT_GEN" != "$LATEST_GEN" ]; then
        ${pkgs.libnotify}/bin/notify-send "NixOS : Mise à jour prête" \
          "Une nouvelle version a été générée. Redémarre quand tu veux pour l'activer." \
          --icon=system-software-update \
          --urgency=normal
      fi
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "sinsry";
      Environment = [  # ✅ Liste de variables d'environnement
        "DISPLAY=:0"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      ];
    };
  };
  # Configuration interne de Nix (Flakes et optimisation).
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true; # Mutualise les fichiers pour gagner de la place.
      download-buffer-size = 134217728; # 128 MB pour des téléchargements plus rapides.
    };
    # Nettoyage automatique des anciennes versions (Garbage Collector).
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d"; # Garde 30 jours d'historique.
    };
  };

  # --- THÈME ET FIN ---
  # Force le thème Plasma sur les applications GTK et Qt.
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };

  # Thème de curseur uniforme.
  environment.variables.XCURSOR_THEME = "breeze_cursors";

  # Permet aux applications de sauvegarder leurs réglages.
  programs.dconf.enable = true;

  environment.sessionVariables = {
  GTK_THEME = "Breeze-Dark";
  };

  # Rebuild + push alias
  environment.shellAliases = {
    rebuild = ''
      sudo nixos-rebuild switch --flake /etc/nixos#travail
    '';
    nixpush = "cd /etc/nixos && sudo git add . && sudo git commit -m 'Update' && sudo git push";
  };

  # Version de NixOS d'origine (ne pas changer sans lire la doc).
  system.stateVersion = "25.11";
}

{ _config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./network-mounts.nix
    ./disks-mounts.nix
  ];


  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    initrd.systemd.enable = true;
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "video=1920x1080@60"
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "amdgpu.dcverbose=0"
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
      timeout = 0;
      systemd-boot = {
        enable = true;
        consoleMode = "max";
      };

      efi.canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.samba-smbd.wantedBy = lib.mkForce [];
  systemd.services.samba-nmbd.wantedBy = lib.mkForce [];
  systemd.services.samba-winbindd.wantedBy = lib.mkForce [];

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
  };

  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    nvd
    rar
    libnotify
    google-chrome
    meld
    cifs-utils
    nfs-utils
    nil
    nixfmt
    psmisc
    git
    discord
    vlc
    mpv
    ffmpeg
    papirus-icon-theme
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

  programs.firefox = {
    enable = true;
    languagePacks = [ "fr" ];
    preferences = {
      "intl.locale.requested" = "fr";
    };
    nativeMessagingHosts.packages = [ pkgs.kdePackages.plasma-browser-integration ];
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
      credential.helper = "cache --timeout=604800";
    };
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "04:00";
  };

  systemd.services.nixos-upgrade-notification = {
    description = "Notification de mise à jour NixOS intelligente";
    after = [ "nixos-upgrade.service" ];
    wantedBy = [ "nixos-upgrade.service" ];

    script = ''
      CURRENT_GEN=$(readlink /run/current-system)
      LATEST_GEN=$(readlink /nix/var/nix/profiles/system)

      if [ "$CURRENT_GEN" != "$LATEST_GEN" ]; then
        ${pkgs.libnotify}/bin/notify-send "NixOS : Mise à jour prête" \
          "Mise à jour effectuée." \
          --icon=system-software-update \
          --urgency=normal
      fi
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "sinsry";
      Environment = [
        "DISPLAY=:0"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      ];
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 12;
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      download-buffer-size = 1073741824;
      max-jobs = "auto";
      cores = 0;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    };
  };

  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };

  programs.dconf.enable = true;

  environment.sessionVariables = {
    GTK_THEME = "Breeze-Dark";
  };

  environment.shellAliases = {
    nixrebuild = ''cd /etc/nixos && sudo git add . && (sudo git commit -m 'Update' || true) && sudo git push && cd ~/ && sudo nixos-rebuild switch --flake path:/etc/nixos#travail'';
    nixpush = "cd /etc/nixos && sudo git add . && (sudo git commit -m 'Update' || true ) && sudo git push && cd ~/";
    nixlistenv = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    nixgarbage = "sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system && sudo nix-collect-garbage -d && sudo nixos-rebuild boot";

  };

  environment.etc."libinput/local-overrides.quirks".source = ./asset/maousse/local-overrides.quirks;

  environment.etc."inputrc".text = ''
    set completion-ignore-case on
    set show-all-if-ambiguous on
    set completion-map-case on
  '';

  programs.bash.interactiveShellInit = ''
    fastfetch
  '';

  system.stateVersion = "25.11";
}

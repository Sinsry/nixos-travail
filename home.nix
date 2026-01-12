{ _config, _pkgs, ... }:

{
  home.stateVersion = "25.11";

  # Config KDE/Plasma
  programs.plasma = {
    enable = true;
    workspace.numlock = "on";
  };
}

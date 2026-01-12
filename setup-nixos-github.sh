#!/usr/bin/env nix-shell
#! nix-shell -i bash -p git

echo "=== Configuration post-installation NixOS ==="
echo ""
echo "⚠️  Lance ce script APRÈS l'installation graphique, AVANT de redémarrer !"
echo ""
read -p "L'installation graphique est terminée ? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Lance d'abord l'installeur graphique !"
    exit 1
fi

# 1. Sauvegarde le hardware-configuration.nix généré par l'installeur
echo "Sauvegarde du hardware-configuration.nix..."
sudo cp /etc/nixos/hardware-configuration.nix /tmp/hardware-configuration.nix.backup

# 2. Sauvegarde complète (au cas où)
echo "Sauvegarde de la config générée..."
sudo cp -r /etc/nixos /etc/nixos.backup

# 3. Vide le contenu de /etc/nixos
echo "Suppression de la config générée..."
sudo rm -rf /etc/nixos/*
sudo rm -rf /etc/nixos/.git* 2>/dev/null || true

# 4. Clone ta vraie config
echo "Clonage de ta configuration depuis GitHub..."
cd /etc/nixos
sudo git clone https://github.com/Sinsry/nixos-config .

# 5. Restaure le hardware-configuration.nix de cette machine
echo "Restauration du hardware-configuration.nix de cette machine..."
sudo cp /tmp/hardware-configuration.nix.backup /etc/nixos/hardware-configuration.nix

# 6. Configure SSH
echo ""
echo "Configuration SSH..."
ssh-keygen -t ed25519 -C "Sinsry@users.noreply.github.com" -f ~/.ssh/id_ed25519 -N ""

echo ""
echo "=== 🔑 Clé publique SSH (à copier) ==="
cat ~/.ssh/id_ed25519.pub
echo "=================================="
echo ""
echo "1. Va sur https://github.com/settings/ssh/new"
echo "2. Colle la clé ci-dessus"
echo "3. Titre : 'NixOS $(date +%Y-%m-%d)'"
echo "4. Clique sur 'Add SSH key'"
echo ""
read -p "Appuie sur Entrée quand c'est fait..."

# 7. Copie SSH pour root
echo ""
echo "Configuration SSH pour root..."
sudo mkdir -p /root/.ssh
sudo cp ~/.ssh/id_ed25519* /root/.ssh/
sudo chmod 600 /root/.ssh/id_ed25519
sudo chmod 644 /root/.ssh/id_ed25519.pub

# 8. Change vers SSH
cd /etc/nixos
sudo git remote set-url origin git@github.com:Sinsry/nixos-config.git

# 9. Rebuild avec ta vraie config
echo ""
echo "Rebuild du système avec ta configuration..."
sudo nixos-rebuild switch --flake /etc/nixos#maousse

echo ""
echo "✅ Configuration terminée !"
echo ""
echo "Tu peux maintenant redémarrer pour profiter de ton système complet ! 🎉"

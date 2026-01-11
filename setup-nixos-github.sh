#!/usr/bin/env bash

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

# 1. Sauvegarde la config générée (au cas où)
echo "Sauvegarde de la config générée..."
sudo cp -r /etc/nixos /etc/nixos.backup

# 2. Supprime la config générée
echo "Suppression de la config générée..."
sudo rm -rf /etc/nixos/*

# 3. Clone ta vraie config
echo "Clonage de ta configuration depuis GitHub..."
sudo git clone https://github.com/Sinsry/nixos-config /mnt/etc/nixos

# 4. Configure SSH
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

# 5. Copie SSH pour root
echo ""
echo "Configuration SSH pour root..."
sudo mkdir -p /root/.ssh
sudo cp ~/.ssh/id_ed25519* /root/.ssh/
sudo chmod 600 /root/.ssh/id_ed25519
sudo chmod 644 /root/.ssh/id_ed25519.pub

# 6. Change vers SSH
cd /etc/nixos
sudo git remote set-url origin git@github.com:Sinsry/nixos-config.git

# 7. Rebuild avec ta vraie config
echo ""
echo "Installation du système avec ta configuration..."
sudo nixos-install --flake /etc/nixos#maousse --no-root-password

echo ""
echo "✅ Installation terminée !"
echo "Redémarre maintenant pour utiliser ton système complet ! 🎉"

echo ""
echo "✅ Configuration terminée !"
echo ""
echo "Tu peux maintenant :"
echo "1. Fermer ce terminal"
echo "2. Cliquer sur 'Redémarrer' dans l'installeur"
echo ""
echo "Au prochain démarrage, tu auras ton système complet avec toute ta config ! 🎉"

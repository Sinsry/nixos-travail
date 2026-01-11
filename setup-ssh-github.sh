#!/usr/bin/env bash

echo "=== Configuration SSH pour NixOS + GitHub ==="
echo ""

# 1. Génère une nouvelle clé SSH
echo "Génération de la clé SSH..."
ssh-keygen -t ed25519 -C "Sinsry@users.noreply.github.com" -f ~/.ssh/id_ed25519 -N ""

# 2. Affiche la clé publique
echo ""
echo "=== Clé publique SSH (à copier) ==="
cat ~/.ssh/id_ed25519.pub
echo ""
echo "=== Copie cette clé ci-dessus ==="
echo ""

# 3. Instructions pour GitHub
echo "Maintenant :"
echo "1. Va sur https://github.com/settings/ssh/new"
echo "2. Colle la clé ci-dessus"
echo "3. Titre : 'NixOS $(date +%Y-%m-%d)'"
echo "4. Clique sur 'Add SSH key'"
echo ""
read -p "Appuie sur Entrée quand c'est fait..."

# 4. Copie pour root
echo ""
echo "Copie de la clé pour root..."
sudo mkdir -p /root/.ssh
sudo cp ~/.ssh/id_ed25519* /root/.ssh/
sudo chmod 600 /root/.ssh/id_ed25519
sudo chmod 644 /root/.ssh/id_ed25519.pub

echo ""
echo "✅ Configuration SSH terminée !"
echo "Tu peux maintenant utiliser Git avec SSH sans mot de passe."

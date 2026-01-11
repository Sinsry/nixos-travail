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

# === Détecte et remonte les partitions ===
echo ""
echo "Détection et montage des partitions..."

# Trouve la partition avec label "root" ou "nixos"
ROOT_PART=$(lsblk -nlo NAME,LABEL | grep -i 'root\|nixos' | awk '{print "/dev/"$1}' | head -1)

# Trouve la partition EFI (type vfat, ~512M-1G)
EFI_PART=$(lsblk -nlo NAME,SIZE,FSTYPE | grep 'vfat' | awk '$2 ~ /^(512M|1G)$/ {print "/dev/"$1}' | head -1)

# Vérifie qu'on a bien trouvé les partitions
if [ -z "$ROOT_PART" ]; then
    echo "❌ Erreur : Impossible de détecter la partition racine !"
    echo "Partitions disponibles :"
    lsblk -o NAME,SIZE,LABEL,FSTYPE
    exit 1
fi

if [ -z "$EFI_PART" ]; then
    echo "❌ Erreur : Impossible de détecter la partition EFI !"
    echo "Partitions disponibles :"
    lsblk -o NAME,SIZE,LABEL,FSTYPE
    exit 1
fi

echo "Partitions détectées :"
echo "  Racine : $ROOT_PART"
echo "  EFI    : $EFI_PART"
echo ""

# Démonte si déjà montés ailleurs
sudo umount "$ROOT_PART" 2>/dev/null || true
sudo umount "$EFI_PART" 2>/dev/null || true

# Monte correctement
echo "Montage de $ROOT_PART sur /mnt..."
sudo mount "$ROOT_PART" /mnt

echo "Montage de $EFI_PART sur /mnt/boot..."
sudo mkdir -p /mnt/boot
sudo mount "$EFI_PART" /mnt/boot

# Vérifie que ça a marché
if ! mountpoint -q /mnt || ! mountpoint -q /mnt/boot; then
    echo "❌ Erreur : Échec du montage !"
    exit 1
fi

# 1. Sauvegarde la config générée (au cas où)
echo "Sauvegarde de la config générée..."
sudo cp -r /mnt/etc/nixos /mnt/etc/nixos.backup

# 2. Supprime la config générée
echo "Suppression de la config générée..."
sudo rm -rf /mnt/etc/nixos/*

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
cd /mnt/etc/nixos
sudo git remote set-url origin git@github.com:Sinsry/nixos-config.git

# 7. Rebuild avec ta vraie config
echo ""
echo "Installation du système avec ta configuration..."
sudo nixos-install --flake /mnt/etc/nixos#maousse --no-root-password

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

#!/bin/bash

echo -e "\n🔥 Welcome to the Ecoholic Server Setup Script 🔥\n"

ask() {
    read -p "$1 [y/n]: " answer
    case "$answer" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

if ask "🚀 Update and upgrade system packages?"; then
    sudo apt update -y && sudo apt upgrade -y
fi

if ask "📦 Install common packages (curl, wget, git, etc)?"; then
    sudo apt install -y curl wget git ufw fail2ban htop unzip zip build-essential
fi

if ask "🧱 Setup UFW firewall and allow SSH?"; then
    sudo ufw allow OpenSSH
    sudo ufw --force enable
fi

if ask "🛡️ Enable and start Fail2Ban?"; then
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
fi

if ask "👤 Create a new sudo user?"; then
    read -p "Enter new username: " NEW_USER
    if ! id "$NEW_USER" &>/dev/null; then
        sudo adduser --disabled-password --gecos "" "$NEW_USER"
        sudo usermod -aG sudo "$NEW_USER"
        echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$NEW_USER"
        echo "✅ User '$NEW_USER' created and given sudo access."
    else
        echo "⚠️ User '$NEW_USER' already exists."
    fi
fi

echo -e "\n✅ All selected tasks completed. You’re all set! 🚀\n"

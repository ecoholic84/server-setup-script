#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║🔥 Welcome to the Ecoholic Server Setup Script 🔥║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}🚀 Starting Interactive Server Setup Script...${NC}"


ask() {
    read -p "$1 (y/n): " choice
    case "$choice" in
        y|Y ) return 0 ;;
        * ) return 1 ;;
    esac
}

# === 1. Update & Upgrade ===
if ask "🔄 Do you want to update and upgrade the system?"; then
    sudo apt update && sudo apt upgrade -y
fi

# === 2. Install Basic Tools ===
if ask "🛠 Do you want to install essential tools (curl, git, htop, ufw, fail2ban)?"; then
    sudo apt install -y curl wget git ufw fail2ban htop
fi

# === 3. Set Timezone ===
if ask "🌍 Do you want to set the timezone to Asia/Kolkata?"; then
    sudo timedatectl set-timezone Asia/Kolkata
fi

# === 4. Create a New User ===
if ask "👤 Do you want to create a new sudo user?"; then
    read -p "Enter new username: " newuser
    sudo adduser $newuser
    sudo usermod -aG sudo $newuser
    echo "✅ User '$newuser' added to sudo group."
fi

# === 5. SSH Hardening ===
if ask "🔐 Do you want to harden SSH (disable root login & password auth)?"; then
    sudo sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
    sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart ssh
    echo "✅ SSH hardened."
fi

# === 6. UFW Firewall ===
if ask "🛡 Do you want to enable UFW (firewall) and allow SSH?"; then
    sudo ufw allow OpenSSH
    sudo ufw enable
    sudo ufw status
fi

# === 7. Fail2Ban ===
if ask "🧱 Do you want to enable Fail2Ban for extra security?"; then
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    echo "✅ Fail2Ban is active."
fi

# === 8. Final Note ===
echo ""
echo "🎉 Setup complete!"
if [ ! -z "$newuser" ]; then
    echo "👉 Remember to copy your SSH public key to /home/$newuser/.ssh/authorized_keys"
fi
echo "👉 And consider disabling password login fully after confirming SSH access works."


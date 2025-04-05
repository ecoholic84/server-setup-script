#!/bin/bash
#
# Debian/Ubuntu Server Initial Configuration Script
# Preconfigured for UFW firewall, with password authentication enabled

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Function to display section headers
section() {
    echo -e "\n${BOLD}${GREEN}=== $1 ===${NC}\n"
}

# Function to prompt for yes/no confirmation
confirm() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run with sudo or as root user"
    exit 1
fi

# Check if system is Debian/Ubuntu based
if [ ! -f /etc/debian_version ]; then
    echo -e "${RED}Error: This script is designed for Debian/Ubuntu systems only${NC}"
    exit 1
fi

# Welcome message
clear
echo -e "${BOLD}${GREEN}"
echo "======================================================="
echo "    Debian/Ubuntu Server Initial Configuration Script  "
echo "=======================================================${NC}"
echo
echo "This script will configure your server with:"
echo "  • System updates"
echo "  • Hostname configuration"
echo "  • User management"
echo "  • UFW firewall configuration"
echo "  • SSH with password authentication"
echo "  • Asia/Kolkata timezone"
echo "  • Common utility installation"
echo

if ! confirm "Do you want to continue?"; then
    echo "Setup canceled."
    exit 0
fi

# Update system
section "System Update"
echo "Updating package lists..."
apt-get update

if confirm "Upgrade all packages? (This might take a while)"; then
    echo "Upgrading packages..."
    apt-get upgrade -y
fi

# Hostname configuration
section "Hostname Configuration"
current_hostname=$(hostname)
echo "Current hostname: $current_hostname"
if confirm "Would you like to change the hostname?"; then
    read -p "Enter new hostname: " new_hostname
    hostnamectl set-hostname "$new_hostname"
    echo "Hostname changed to $new_hostname"
    
    # Update /etc/hosts
    sed -i "s/127.0.1.1.*$current_hostname/127.0.1.1\t$new_hostname/g" /etc/hosts
    echo "Updated /etc/hosts file"
fi

# User management
section "User Management"
if confirm "Create a new administrative user? (Recommended for security)"; then
    read -p "Enter username: " username
    adduser --disabled-password --gecos "" "$username"
    echo "Set a password for $username:"
    passwd "$username"
    usermod -aG sudo "$username"
    echo "User $username added to sudoers"
    echo -e "${YELLOW}New administrative user $username created${NC}"
    echo -e "${GREEN}✓ You can now SSH to this server using: ssh $username@server_ip${NC}"
fi

# SSH Configuration
section "SSH Configuration"
if [ -f /etc/ssh/sshd_config ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    echo "Original SSH configuration backed up to /etc/ssh/sshd_config.backup"
    
    # Disable root login
    if confirm "Disable SSH root login? (Recommended)"; then
        sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
        echo "Root login via SSH disabled"
    fi
    
    # Change SSH port
    if confirm "Change SSH port? (Can help reduce automated attacks)"; then
        read -p "Enter new SSH port (recommended between 1024-65535): " ssh_port
        sed -i "s/^#*Port .*/Port $ssh_port/" /etc/ssh/sshd_config
        echo "SSH port changed to $ssh_port"
        echo -e "${YELLOW}Remember to update your firewall rules and connect using -p $ssh_port${NC}"
    fi
    
    # Explicitly configure password authentication
    echo -e "${GREEN}Ensuring password authentication is enabled...${NC}"
    
    # First, make sure ChallengeResponseAuthentication is yes
    if grep -q "^#ChallengeResponseAuthentication" /etc/ssh/sshd_config; then
        sed -i 's/^#ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    elif grep -q "^ChallengeResponseAuthentication" /etc/ssh/sshd_config; then
        sed -i 's/^ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    else
        echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config
    fi
    
    # Make sure password authentication is explicitly enabled
    if grep -q "^#PasswordAuthentication" /etc/ssh/sshd_config; then
        sed -i 's/^#PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    elif grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
        sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    else
        echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
    fi
    
    # Make sure UsePAM is enabled
    if grep -q "^#UsePAM" /etc/ssh/sshd_config; then
        sed -i 's/^#UsePAM .*/UsePAM yes/' /etc/ssh/sshd_config
    elif grep -q "^UsePAM" /etc/ssh/sshd_config; then
        sed -i 's/^UsePAM .*/UsePAM yes/' /etc/ssh/sshd_config
    else
        echo "UsePAM yes" >> /etc/ssh/sshd_config
    fi
    
    echo -e "${GREEN}✓ SSH password authentication is now explicitly enabled${NC}"
    echo -e "${GREEN}✓ Users can login using: ssh username@server_ip${NC}"
    
    # Restart SSH service
    systemctl restart sshd
    echo "SSH service restarted with new configuration"
fi

# Firewall setup with UFW
section "UFW Firewall Configuration"
# Install UFW if not already installed
apt-get install -y ufw

# Configure UFW
echo "Configuring UFW firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh

# If SSH port was changed
if [ ! -z ${ssh_port+x} ]; then
    ufw allow "$ssh_port/tcp"
fi

if confirm "Allow HTTP (port 80)?"; then
    ufw allow http
fi

if confirm "Allow HTTPS (port 443)?"; then
    ufw allow https
fi

# Enable UFW
echo "Enabling UFW firewall..."
ufw --force enable
echo "UFW firewall configured and enabled"

# Install common utilities
section "Utility Installation"
utilities=("vim" "htop" "tmux" "fail2ban")
if confirm "Install common server utilities (vim, htop, tmux, fail2ban)?"; then
    echo "Installing utilities: ${utilities[*]}"
    apt-get install -y "${utilities[@]}"
    echo "Utilities installed"
fi

# Set timezone to Asia/Kolkata
section "Timezone Configuration"
echo "Setting timezone to Asia/Kolkata..."
timedatectl set-timezone Asia/Kolkata
echo "Timezone set to $(timedatectl | grep "Time zone" | awk '{print $3}')"

# Configure NTP for accurate time
timedatectl set-ntp true
echo "NTP enabled via systemd-timesyncd"

# Set up automatic updates
section "Automatic Updates"
if confirm "Configure automatic security updates?"; then
    apt-get install -y unattended-upgrades apt-listchanges
    dpkg-reconfigure -plow unattended-upgrades
    echo "Automatic security updates configured"
fi

# System summary
section "System Configuration Summary"
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -I | awk '{print $1}')"
echo "Firewall status:"
ufw status
echo "Timezone: $(timedatectl | grep "Time zone" | awk '{print $3}')"
echo "SSH Authentication: Password authentication ENABLED"

# Login information
section "Login Information"
echo -e "${GREEN}✓ SSH is configured with password authentication enabled${NC}"
if [ ! -z ${username+x} ]; then
    echo -e "${GREEN}✓ You can login with: ssh $username@$(hostname -I | awk '{print $1}')${NC}"
    if [ ! -z ${ssh_port+x} ]; then
        echo -e "${GREEN}✓ Using custom port: ssh -p $ssh_port $username@$(hostname -I | awk '{print $1}')${NC}"
    fi
fi

# Finished
section "Setup Complete"
echo -e "${GREEN}Initial server configuration completed successfully!${NC}"
echo
echo "Here are some recommended next steps:"
echo "  1. Set up regular backups"
echo "  2. Configure monitoring tools"
echo "  3. Install specific software needed for your use case"
echo

# Optional reboot
if confirm "Would you like to reboot the system now to apply all changes?"; then
    echo "Rebooting in 5 seconds... Press Ctrl+C to cancel"
    sleep 5
    reboot
fi

exit 0

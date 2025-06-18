#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Exiting..."
   exit 1
fi

echo "Starting Linux hardening process..."

# 1. Update the system
echo "Updating system packages..."
apt-get update && apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean

# 2. Disable root login
echo "Disabling root login..."
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin/PermitRootLogin no/' /etc/ssh/sshd_config

# 3. Enforce SSH key-based authentication
echo "Configuring SSH to use key-based authentication..."
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# 4. Change SSH port to 2222 (optional, adjust as needed)
echo "Changing SSH port to 2222..."
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 2222/' /etc/ssh/sshd_config

# 5. Restart SSH service
echo "Restarting SSH service..."
systemctl restart sshd

# 6. Install and configure UFW (Uncomplicated Firewall)
echo "Installing and configuring UFW..."
apt-get install ufw -y
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp  # Allow new SSH port
ufw allow 80/tcp    # Allow HTTP
ufw allow 443/tcp   # Allow HTTPS
ufw enable
ufw status

# 7. Disable unnecessary services (example: stop and disable telnet if installed)
if systemctl is-active --quiet telnet; then
    echo "Disabling telnet service..."
    systemctl stop telnet
    systemctl disable telnet
fi

# 8. Set up automatic security updates
echo "Configuring automatic security updates..."
apt-get install unattended-upgrades -y
dpkg-reconfigure --priority=low unattended-upgrades

# 9. Harden sysctl settings
echo "Applying sysctl hardening settings..."
cat << EOF > /etc/sysctl.d/99-hardening.conf
# Disable IP forwarding
net.ipv4.ip_forward=0
net.ipv6.conf.all.forwarding=0

# Enable protection against IP spoofing
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0

# Enable TCP SYN cookies
net.ipv4.tcp_syncookies=1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses=1

# Disable source routing
net.ipv4.conf.all.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0

# Disable core dumps
kernel.core_uses_pid=1
fs.suid_dumpable=0
EOF
sysctl -p /etc/sysctl.d/99-hardening.conf

# 10. Restrict core dumps for processes
echo "Restricting core dumps for processes..."
echo "* hard core 0" >> /etc/security/limits.conf
echo "ulimit -c 0" >> /etc/profile
if [ -f /etc/systemd/coredump.conf ]; then
    echo "Configuring systemd coredump settings..."
    sed -i 's/#Storage=external/Storage=none/' /etc/systemd/coredump.conf
    sed -i 's/#ProcessSizeMax=2G/ProcessSizeMax=0/' /etc/systemd/coredump.conf
    systemctl daemon-reload
fi

# 11. Set permissions on sensitive files
echo "Securing sensitive files..."
chmod 600 /etc/ssh/sshd_config
chmod 644 /etc/fstab
chmod 600 /etc/crontab

# 12. Install and configure fail2ban
echo "Installing and configuring fail2ban..."
apt-get install fail2ban -y
cat << EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = 2222
maxretry = 5
bantime = 3600
findtime = 600
EOF
systemctl enable fail2ban
systemctl start fail2ban

# 13. Remove unnecessary users (example: remove 'games' user if exists)
if id "games" &>/dev/null; then
    echo "Removing unnecessary 'games' user..."
    userdel -r games
fi

# 14. Check for world-writable files
echo "Checking for world-writable files..."
find / -xdev -type f -perm -0002 -exec chmod o-w {} \;
echo "World-writable files fixed."

# 15. Enable process accounting
echo "Enabling process accounting..."
apt-get install acct -y
systemctl enable acct
systemctl start acct

echo "Linux hardening complete!"
echo "Please review configurations and test SSH access before logging out."

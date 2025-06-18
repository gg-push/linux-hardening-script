# Linux Hardening Script

## Overview
This Bash script is designed to enhance the security of Debian-based Linux systems (e.g., Ubuntu) by applying common hardening techniques. It configures system settings, secures SSH, sets up a firewall, restricts core dumps, and more to reduce vulnerabilities. The script must be run with root privileges.

## Features
- **System Updates**: Updates and upgrades all packages, removes unnecessary ones, and cleans the package cache.
- **SSH Hardening**: Disables root login, enforces key-based authentication, and changes the SSH port to 2222.
- **Firewall Configuration**: Installs and configures UFW to deny incoming traffic by default, allowing specific ports (2222, 80, 443).
- **Service Management**: Disables unnecessary services like telnet if present.
- **Automatic Updates**: Configures unattended-upgrades for automatic security updates.
- **Sysctl Hardening**: Applies kernel-level security settings to disable IP forwarding, ICMP redirects, and source routing.
- **Core Dump Restriction**: Disables core dumps system-wide to prevent sensitive data leaks.
- **File Permissions**: Secures sensitive configuration files like `/etc/ssh/sshd_config` and `/etc/crontab`.
- **Fail2Ban**: Installs and configures fail2ban to protect against brute-force attacks on SSH.
- **User Management**: Removes unnecessary users (e.g., 'games').
- **File System Security**: Fixes world-writable files.
- **Process Accounting**: Enables process accounting for auditing.

## Prerequisites
- Debian-based Linux distribution (e.g., Ubuntu).
- Root or sudo privileges.
- SSH key pair configured for the user (if password authentication is to be disabled).
- Backup of critical configuration files and system state.

## Usage

1. **Make the Script Executable**:
   ```bash
   chmod +x linux-harden.sh
   ```

2. **Run the Script as Root**:
   ```bash
   sudo ./linux-harden.sh
   ```

## Troubleshooting
- **SSH Access Issues**: If locked out, access the system via console or revert `/etc/ssh/sshd_config` changes.
- **Firewall Blocks**: Check `ufw status` and ensure required ports are open.
- **Core Dumps**: If debugging is needed, comment out the core dump restrictions in `/etc/security/limits.conf` and `/etc/systemd/coredump.conf`.

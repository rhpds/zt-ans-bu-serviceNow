#!/bin/bash

# Network Configuration - Mirror roadshow02 logic
nmcli connection add type ethernet con-name enp2s0 ifname enp2s0 ipv4.addresses 192.168.1.12/24 ipv4.method manual connection.autoconnect yes
nmcli connection up enp2s0

# Hosts file configuration - Mirror roadshow02 logic
echo "192.168.1.10 control.lab control" >> /etc/hosts
echo "192.168.1.11 node01.lab node01" >> /etc/hosts
echo "192.168.1.12 node02.lab node02" >> /etc/hosts

# Satellite Registration - Mirror roadshow02 logic
curl -k -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm

subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}

# Package Installation - Mirror roadshow02 logic with additional packages for ServiceNow
dnf install samba-common-tools realmd oddjob oddjob-mkhomedir sssd adcli krb5-workstation httpd nano -y

# SELinux Configuration - Mirror roadshow02 logic
setenforce 0

# Backup resolv.conf - Mirror roadshow02 logic
cp /etc/resolv.conf /tmp/resolv.conf

# Web Server Configuration - Mirror roadshow02 logic with ServiceNow branding
cat <<EOF | tee /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ServiceNow Lab Environment</title>
    <style>
        body {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
            background-color: #f4f4f9;
            color: #333;
        }
        h1 {
            font-size: 3em;
            text-align: center;
        }
        .container {
            text-align: center;
            padding: 20px;
        }
        .status {
            color: #28a745;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>ServiceNow Lab Environment</h1>
        <p class="status">Node02 is ready for ServiceNow automation</p>
        <p>This server is configured for ServiceNow ITSM integration</p>
    </div>
</body>
</html>
EOF

# Start and enable services - Mirror roadshow02 logic
systemctl enable httpd
systemctl start httpd

# Create backup directory for ServiceNow
mkdir -p /backup
chmod -R 777 /backup

# Additional ServiceNow-specific configurations
echo "ServiceNow Node02 setup completed successfully"

# Stop nginx if running (from original script)
systemctl stop nginx

# Additional ServiceNow-specific packages and configurations
dnf install -y yum-utils jq podman wget git ansible-core

# Firewall configuration for ServiceNow
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --reload

# Set root password for ServiceNow integration
echo "ansible" | passwd root --stdin

# Install Ansible collections for ServiceNow
ansible-galaxy collection install community.general
ansible-galaxy collection install servicenow.itsm

# Create setup directory
mkdir -p /tmp/setup/

# Clone ServiceNow automation repository
git clone https://github.com/nmartins0611/Instruqt_netops.git /tmp/setup/

# SSH Setup for ServiceNow integration
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdQebku7hz6otXEso48S0yjY0mQ5oa3VbFfOvEHeApfu9pNMG34OCzNpRadCDIYEfidyCXZqC91vuVM+6R7ULa/pZcgoeDopYA2wWSZEBIlF9DexAU4NEG4Zc0sHfrbK66lyVgdpvu1wmHT5MEhaCWQclo4B5ixuUVcSjfiM8Y7FL/qOp2FY8QcN10eExQo1CrGBHCwvATxdjgB+7yFhjVYVkYALINDoqbFaituKupqQyCj3FIoKctHG9tsaH/hBnhzRrLWUfuUTMMveDY24PzG5NR3rBFYI3DvKk5+nkpTcnLLD2cze6NIlKW5KygKQ4rO0tJTDOqoGvK5J5EM4Jb" >> /root/.ssh/authorized_keys 
echo "Host *" >> /etc/ssh/ssh_config
echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
echo "UserKnownHostsFile=/dev/null" >> /etc/ssh/ssh_config
chmod 400 /etc/ssh/ssh_config
systemctl restart sshd

echo "ServiceNow Node02 setup completed with full automation capabilities"






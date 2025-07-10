#!/bin/bash

# Network Configuration - Mirror roadshow02 logic
nmcli connection add type ethernet con-name enp2s0 ifname enp2s0 ipv4.addresses 192.168.1.11/24 ipv4.method manual connection.autoconnect yes
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
dnf install samba-common-tools realmd oddjob oddjob-mkhomedir sssd adcli krb5-workstation httpd nano git wget curl tar -y

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
        <p class="status">Node01 is ready for ServiceNow automation</p>
        <p>This server is configured for ServiceNow ITSM integration</p>
        <p><a href="http://node01:8080" target="_blank">VS Code Server</a></p>
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

# VS Code Server Setup using agnosticd role
echo "Setting up VS Code Server..."

# Clone agnosticd with sparse checkout for vscode-server role
cd /tmp
rm -rf agnosticd
git clone --filter=blob:none --no-checkout https://github.com/redhat-cop/agnosticd.git
cd agnosticd
git sparse-checkout init --cone
git sparse-checkout set ansible/roles/vscode-server
git checkout

tee /tmp/agnosticd/ansible/vscode-setup.yml << EOF
---
- hosts: localhost
  become: true
  tasks:
   - include_role:
        name: vscode-server
     vars:
      vscode_user_name: rhel
      vscode_user_password: ansible123!
      vscode_server_hostname: 0.0.0.0
      vscode_server_port: 8080
      vscode_server_install_extension:
        - redhat.ansible
        - ms-python.python
EOF

# Run the ansible playbook
cd /tmp/agnosticd
ansible-playbook -i localhost, -c local vscode-setup.yml

# Create servicenow project directory
mkdir -p /home/rhel/servicenow_project
chown -R rhel:rhel /home/rhel/servicenow_project

# Create VS Code settings directory and settings
mkdir -p /home/rhel/.local/share/code-server/User
cat > /home/rhel/.local/share/code-server/User/settings.json << EOF
{
    "git.ignoreLegacyWarning": true,
    "window.menuBarVisibility": "visible",
    "workbench.colorTheme": "Solarized Dark",
    "ansible.ansibleLint.enabled": true,
    "ansible.ansible.useFullyQualifiedCollectionNames": true,
    "files.associations": {
        "*.yml": "ansible"
    },
    "workbench.tips.enabled": false,
    "workbench.startupEditor": "readme"
}
EOF
chown -R rhel:rhel /home/rhel/.local

# Start and enable code-server
systemctl daemon-reload
systemctl enable code-server
systemctl start code-server

# Install VS Code extensions as rhel user
su - rhel -c 'code-server --install-extension redhat.ansible --force'

echo "VS Code Server setup completed. Access at http://node01:8080 with password: ansible123!"

# Additional ServiceNow-specific configurations
echo "ServiceNow Node01 setup completed successfully"

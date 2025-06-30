# ServiceNow Setup Automation - Mirroring Roadshow02 Logic

## Overview
This setup automation has been updated to mirror the successful configuration from `zt-ans-bu-roadshow02`. The key changes ensure proper network configuration, host setup, and ServiceNow integration.

## Key Changes Made

### 1. Network Configuration (Mirrored from Roadshow02)
- **Static IP Assignment**: Both node01 and node02 now use static IPs (192.168.1.11/24 and 192.168.1.12/24)
- **Network Interface**: Configured enp2s0 interface with NetworkManager
- **Hosts File**: Added proper hostname resolution for all nodes

### 2. Package Installation (Enhanced)
- **Base Packages**: Added AD tools, SELinux utilities, and system packages
- **ServiceNow Packages**: Included Ansible collections for ServiceNow ITSM integration
- **Development Tools**: Added git, wget, jq, and other utilities

### 3. System Configuration
- **SELinux**: Disabled enforcement for lab environment
- **Firewall**: Configured ports 80, 443, and 22 for web and SSH access
- **SSH Configuration**: Set up key-based authentication and disabled host key checking

### 4. ServiceNow Integration
- **Ansible Collections**: Installed `community.general` and `servicenow.itsm`
- **Repository Setup**: Cloned automation repository for ServiceNow integration
- **User Configuration**: Set up root password and SSH keys for automation

### 5. Web Server Configuration
- **Apache HTTPD**: Installed and configured with ServiceNow-branded landing page
- **Service Management**: Enabled and started HTTPD service
- **Backup Directory**: Created `/backup` directory with proper permissions

## Files Updated

### `setup-node01.sh`
- Added network configuration (192.168.1.11/24)
- Enhanced package installation
- Improved web server setup
- Added ServiceNow-specific configurations

### `setup-node02.sh`
- Added network configuration (192.168.1.12/24)
- Enhanced package installation with automation tools
- Added firewall configuration
- Set up SSH and Ansible for ServiceNow integration

### `main.yml`
- Added control host to inventory
- Improved timeout handling (300 seconds instead of 901)
- Added host availability checking
- Enhanced error handling

### `ansible.cfg`
- Added timeout settings (300 seconds)
- Improved SSH configuration
- Added pipelining for better performance

## Network Topology

```
Control Host (192.168.1.10)
├── Node01 (192.168.1.11) - ServiceNow Automation Node
└── Node02 (192.168.1.12) - ServiceNow Automation Node
```

## Environment Variables Required

- `SATELLITE_URL`: Red Hat Satellite server URL
- `SATELLITE_ORG`: Satellite organization
- `SATELLITE_ACTIVATIONKEY`: Satellite activation key
- `BASTION_HOST`: Bastion host for SSH access
- `BASTION_PORT`: SSH port (default: 22)
- `BASTION_USER`: SSH username
- `BASTION_PASSWORD`: SSH password

## Troubleshooting

### Common Issues
1. **Network Connectivity**: Ensure static IPs don't conflict with DHCP
2. **Satellite Registration**: Verify Satellite URL and credentials
3. **SSH Access**: Check firewall rules and SSH service status
4. **Package Installation**: Ensure proper repository access

### Debug Steps
1. Check network configuration: `nmcli connection show`
2. Verify hosts file: `cat /etc/hosts`
3. Test SSH connectivity: `ssh -o StrictHostKeyChecking=no user@host`
4. Check service status: `systemctl status httpd sshd`

## Next Steps

After successful setup:
1. Verify all nodes are reachable via SSH
2. Test ServiceNow integration
3. Run Ansible playbooks for automation
4. Configure ServiceNow ITSM workflows 
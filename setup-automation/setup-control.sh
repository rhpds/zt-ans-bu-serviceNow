#!/bin/bash
USER=rhel
# Install required AWX collection
su - rhel -c 'ansible-galaxy collection install awx.awx'

# Create necessary project directories
su - rhel -c 'mkdir /tmp/admin_project/'
chmod a+x /tmp/admin_project/
su - rhel -c 'mkdir /home/rhel/servicenow_project'
chmod a+x /home/rhel/
su - awx -c 'ln -s /home/rhel/servicenow_project/ /var/lib/awx/projects/'

# Create an inventory file for this environment
tee /tmp/inventory << EOF
[nodes]
node01
node02

[storage]
storage01

[all]
node01
node02
aap

[all:vars]
ansible_user = rhel
ansible_password = ansible123!
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3

EOF

sudo chown rhel:rhel /tmp/inventory


# Controller configuration playbook (local only)
tee /home/rhel/setup-controller.yml << EOF
---
- name: Configure learner Controller 
  hosts: localhost
  connection: local
  collections:
    - ansible.controller
  vars:
    SANDBOX_ID: "{{ lookup('env', '_SANDBOX_ID') | default('SANDBOX_ID_NOT_FOUND', true) }}"
    SN_HOST_VAR: "{{ '{{' }} SN_HOST {{ '}}' }}"
    SN_USER_VAR: "{{ '{{' }} SN_USERNAME {{ '}}' }}"
    SN_PASSWORD_VAR: "{{ '{{' }} SN_PASSWORD {{ '}}' }}"

  tasks:
    - name: Add EE to the controller instance
      ansible.controller.execution_environment:
      name: "RHEL EE"
      image: quay.io/acme_corp/rhel_90_ee:latest
      controller_host: "https://localhost"
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false
    
    - name: Add EE to the controller instance
      ansible.controller.execution_environment:
      name: "ServiceNow EE"
      image: quay.io/acme_corp/servicenow-ee:latest
      controller_host: "https://localhost"
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false

    - name: add ServiceNow Type
      ansible.controller.credential_type:
      name: ServiceNow
      description: ServiceNow Credential
      kind: cloud
      inputs: 
        fields:
          - id: SN_HOST
            type: string
            label: SNOW Instance
          - id: SN_USERNAME
            type: string
            label: SNOW Username
          - id: SN_PASSWORD
            type: string
            secret: true
            label: SNOW Password
        required:
          - SN_HOST
          - SN_USERNAME
          - SN_PASSWORD
      injectors:
          env:
           SN_HOST: "{{ SN_HOST_VAR }}"
           SN_USERNAME: "{{ SN_USER_VAR }}"
           SN_PASSWORD: "{{ SN_PASSWORD_VAR }}"
      state: present
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false

  - name: add snow credential
    ansible.controller.credential:
      name: 'ServiceNow'
      organization: Default
      credential_type: ServiceNow
      controller_host: "https://localhost"
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false
      inputs:
        SN_USERNAME: aap-roadshow
        SN_PASSWORD: Ans1ble123!
        SN_HOST: https://ansible.service-now.com

    - name: add rhel machine credential
      awx.awx.credential:
        name: 'rhel credential'
        organization: Default
        credential_type: Machine
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
        inputs:
          username: rhel
          password: ansible123!

    - name: add rhel inventory
      awx.awx.inventory:
        name: "rhel inventory"
        description: "rhel servers in demo environment"
        organization: "Default"
        state: present
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false

    - name: add hosts
      awx.awx.host:
        name: "{{ item }}"
        description: "rhel host"
        inventory: "rhel inventory"
        state: present
        enabled: true
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      loop:
        - node1
        - node2

    - name: Add group
      awx.awx.group:
        name: nodes
        description: "rhel host group"
        inventory: rhel inventory
        hosts:
          - node1
          - node2
        variables:
          ansible_user: rhel
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false

    - name: Add student project
      awx.awx.project:
        name: "ServiceNow"
        description: "Project containing users ServiceNow playbooks"
        organization: Default
        state: present
        scm_type: git
        scm_url: https://github.com/cloin/instruqt-snow
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false

    - name: Add admin project
      awx.awx.project:
        name: "ServiceNow - admin"
        description: "Project containing users ServiceNow playbooks for admin use"
        organization: Default
        state: present
        scm_type: git
        scm_url: https://github.com/cloin/instruqt-snow
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false

    - name: Post SNOW user create job template
      job_template:
        name: "0 - Create SNOW demo user"
        job_type: "run"
        organization: "Default"
        inventory: "Demo Inventory"
        project: "ServiceNow - admin"
        playbook: "admin_project/create-snow-user.yml"
        execution_environment: "ServiceNow EE"
        ask_variables_on_launch: true
        credentials:
          - "servicenow credential"
        state: "present"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false

    - name: Launch SNOW user create/destroy job
      awx.awx.job_launch:
        job_template: "0 - Create SNOW demo user"
        extra_vars:
          cleanup: false
        controller_host: https://localhost
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false

EOF

# chown above file
sudo chown rhel:rhel /home/rhel/setup-controller.yml

# Run playbook 
echo "execute setup-controller playbook"
su - rhel -c 'ansible-playbook /home/rhel/setup-controller.yml'

EOF'

# Enable linger so podman can function for user
su - $USER -c 'loginctl enable-linger $USER'


# Write ansible-navigator config
su - $USER -c 'cat >/home/rhel/servicenow_project/ansible-navigator.yml <<EOL
---
ansible-navigator:
  execution-environment:
    enabled: true
    container-engine: podman
    image: quay.io/acme_corp/servicenow-ee:latest
    pull:
      policy: never
    environment-variables:
      pass:
        - SN_HOST
        #- SN_USERNAME
        #- SN_PASSWORD
  playbook-artifact:
    enable: true
    save-as: "{playbook_dir}/artifacts/{playbook_name}-artifact-{time_stamp}.json"
  logging:
    append: true
    file: 'artifacts/ansible-navigator.log'
    level: warning
  editor:
    console: false
EOL'

# Set environment variables in bashrc for navigator
su - $USER -c 'echo "export SN_HOST=https://ansible.service-now.com" >> /home/rhel/.bashrc'

# Clean up old navigator
su - $USER -c 'sudo dnf -y remove ansible-navigator'

# Download checker playbooks
wget -O /tmp/check-jt-run.yml https://raw.githubusercontent.com/cloin/snow-demo-setup/main/track_check_scripts/check-jt-run.yml
wget -O /tmp/check-inventory-sync.yml https://raw.githubusercontent.com/cloin/snow-demo-setup/main/track_check_scripts/check-inventory-sync.yml

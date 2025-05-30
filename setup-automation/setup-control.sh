# #!/bin/bash
# #
# # echo "$ADMIN_CONTROLLER_PASSWORD" >> /tmp/passwd

# # Set AAP url for Controler
# # echo "CONTROLLER URL"
# # vars set using `agent variable set` are available in the environment and can be used in challenge text
# # agent variable set SANDBOX $INSTRUQT_PARTICIPANT_ID

# # CONTROLLER_URL=$(echo https://$HOSTNAME.$_SANDBOX_ID.instruqt.io/api/controller)

# # agent variable set CONTROLLER_URL $CONTROLLER_URL

# # export CONTROLLER_URL=$(echo https://$HOSTNAME.$_SANDBOX_ID.instruqt.io/api/controller)

# # DNS=$(echo $_SANDBOX_ID)

# # agent variable set DNS_DETAIL $DNS

# # export DNS_DETAIL=$(echo $_SANDBOX_ID.instruqt.io)

# #agent variable set DNS-DOMAIN ${$_SANDBOX_ID}.svc.cluster.local

# # export DOMAIN_DNS="$(echo $_SANDBOX_ID.svc.cluster.local)"
# # agent variable set DOMAIN $DOMAIN_DNS

# # Install collection(s)
# su - rhel -c 'ansible-galaxy collection install ansible.eda'
# su - rhel -c 'ansible-galaxy collection install community.general'
# su - rhel -c 'ansible-galaxy collection install ansible.windows'
# su - rhel -c 'ansible-galaxy collection install microsoft.ad'

# ## setup rhel user
# touch /etc/sudoers.d/rhel_sudoers
# echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
# cp -a /root/.ssh/* /home/$USER/.ssh/.
# chown -R rhel:rhel /home/$USER/.ssh

# # Create an inventory file for this environment
# tee /tmp/inventory << EOF
# [nodes]
# node01
# node02

# [storage]
# storage01

# [ciservers]
# gitea ansible_user=root ansible_become_method=su

# [all]
# node01
# node02
# # eda-controller
# # controller
# aap

# [all:vars]
# ansible_user = rhel
# ansible_password = ansible123!
# ansible_ssh_common_args='-o StrictHostKeyChecking=no'
# ansible_python_interpreter=/usr/bin/python3

# EOF

# cat <<EOF | tee /tmp/git-setup.yml

# # Gitea config
# - name: Configure Gitea host
#   hosts: gitea
#   gather_facts: false
#   become: true
#   tags:
#     - gitea-config

#   vars:

#     student_user: student
#     student_password: learn_ansible

#   tasks:
#     - name: Install python3 Gitea
#       ansible.builtin.raw: /sbin/apk add python3

#     - name: Install Gitea packages
#       community.general.apk:
#         name: subversion, tar
#         state: present

#     - name: Create repo users
#       ansible.builtin.command: "{{ item }}"
#       become_user: git
#       register: __output
#       failed_when: __output.rc not in [ 0, 1 ]
#       changed_when: '"user already exists" not in __output.stdout'
#       loop:
#         - "/usr/local/bin/gitea admin user create --admin --username {{ student_user }} --password {{ student_password }} --must-change-password=false --email {{ student_user }}@localhost"

#     - name: Store repo credentials in git-creds file
#       ansible.builtin.copy:
#         dest: /tmp/git-creds
#         mode: 0644
#         content: "http://{{ student_user }}:{{ student_password }}@{{ 'gitea:3000' | urlencode }}"

#     - name: Configure git username
#       community.general.git_config:
#         name: user.name
#         scope: global
#         value: "{{ ansible_user }}"

#     - name: Configure git email address
#       community.general.git_config:
#         name: user.email
#         scope: global
#         value: "{{ ansible_user }}@local"

#     - name: Grab the rsa
#       ansible.builtin.set_fact:
#         controller_ssh: "{{ lookup('file', '/home/rhel/.ssh/id_rsa.pub') }}"

#     - name: Migrate github projects to gitea student user
#       ansible.builtin.uri:
#         url: http://gitea:3000/api/v1/repos/migrate
#         method: POST
#         body_format: json
#         body: {"clone_addr": "{{ item.url }}", "repo_name": "{{ item.name }}"}
#         status_code: [201, 409]
#         headers:
#           Content-Type: "application/json"
#         user: student
#         password: learn_ansible
#         force_basic_auth: yes
#         validate_certs: no
#       loop:
#         - {name: 'aap25-roadshow-content', url: 'https://github.com/nmartins0611/aap25-roadshow-content.git'}
# EOF

# sudo chown rhel:rhel /tmp/inventory


# # creates a playbook to setup environment
# tee /tmp/setup.yml << EOF
# ---
# ### Automation Controller setup 
# ###
# - name: Setup Controller 
#   hosts: localhost
#   connection: local
#   collections:
#     - ansible.controller
#   vars:
#     SANDBOX_ID: "{{ lookup('env', '_SANDBOX_ID') | default('SANDBOX_ID_NOT_FOUND', true) }}"
#   tasks:

#   - name: (EXECUTION) add App machine credential
#     ansible.controller.credential:
#       name: 'Application Nodes'
#       organization: Default
#       credential_type: Machine
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false
#       inputs:
#         username: rhel
#         password: ansible123!

#   - name: (EXECUTION) add Windows machine credential
#     ansible.controller.credential:
#       name: 'Windows Nodes'
#       organization: Default
#       credential_type: Machine
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false
#       inputs:
#         username: instruqt
#         password: Passw0rd!

#   - name: (EXECUTION) add Arista credential
#     ansible.controller.credential:
#       name: 'Arista Network'
#       organization: Default
#       credential_type: Machine
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false
#       inputs:
#         username: ansible
#         password: ansible

#   - name: Add Network EE
#     ansible.controller.execution_environment:
#       name: "Edge_Network_ee"
#       image: quay.io/acme_corp/network-ee
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add Windows EE
#     ansible.controller.execution_environment:
#       name: "Windows_ee"
#       image: quay.io/acme_corp/windows-ee
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add RHEL EE
#     ansible.controller.execution_environment:
#       name: "Rhel_ee"
#       image: quay.io/acme_corp/rhel_90_ee
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add Video platform inventory
#     ansible.controller.inventory:
#       name: "Video Platform Inventory"
#       description: "Nodes used for streaming"
#       organization: "Default"
#       state: present
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add Streaming Server hosts
#     ansible.controller.host:
#       name: "{{ item }}"
#       description: "Application Nodes"
#       inventory: "Video Platform Inventory"
#       state: present
#       enabled: true
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false
#     loop:
#       - node01
#       - node02
#       - node03
 
#   - name: Add Streaming server group
#     ansible.controller.group:
#       name: "Streaming_Infrastucture"
#       description: "Streaming Nodes"
#       inventory: "Video Platform Inventory"
#       hosts:
#         - node01
#         - node02
#         - node03
#       variables:
#         ansible_user: rhel
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add Streaming server group
#     ansible.controller.group:
#       name: "Reporting"
#       description: "Report Servers"
#       inventory: "Video Platform Inventory"
#       hosts:
#         - node03
#       variables:
#         ansible_user: rhel
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false


#   #   # Network
 
#   - name: Add Edge Network Devices
#     ansible.controller.inventory:
#       name: "Edge Network"
#       description: "Network for delivery"
#       organization: "Default"
#       state: present
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add CEOS1
#     ansible.controller.host:
#       name: "ceos01"
#       description: "Edge Leaf"
#       inventory: "Edge Network"
#       state: present
#       enabled: true
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false
#       variables:
#         ansible_host: node02
#         ansible_port: 2001

#   - name: Add CEOS2
#     ansible.controller.host:
#       name: "ceos02"
#       description: "Edge Leaf"
#       inventory: "Edge Network"
#       state: present
#       enabled: true
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false
#       variables:
#         ansible_host: node02
#         ansible_port: 2002

#   - name: Add CEOS3
#     ansible.controller.host:
#       name: "ceos03"
#       description: "Edge Leaf"
#       inventory: "Edge Network"
#       state: present
#       enabled: true
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false
#       variables:
#         ansible_host: node02
#         ansible_port: 2003

#   - name: Add EOS Network Group
#     ansible.controller.group:
#       name: "Delivery_Network"
#       description: "EOS Network"
#       inventory: "Edge Network"
#       hosts:
#         - ceos01
#         - ceos02
#         - ceos03
#       variables:
#         ansible_user: ansible
#         ansible_connection: ansible.netcommon.network_cli 
#         ansible_network_os: arista.eos.eos 
#         ansible_password: ansible 
#         ansible_become: yes 
#         ansible_become_method: enable
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false
      
#   #   ## Extra Inventories 

#   # - name: Add Storage Infrastructure
#   #   ansible.controller.inventory:
#   #    name: "Cache Storage"
#   #    description: "Edge NAS Storage"
#   #    organization: "Default"
#   #    state: present
#   #    controller_host: "https://localhost"
#   #    controller_username: admin
#   #    controller_password: ansible123!
#   #    validate_certs: false

#   # - name: Add Storage Node
#   #   ansible.controller.host:
#   #    name: "Storage01"
#   #    description: "Edge NAS Storage"
#   #    inventory: "Cache Storage"
#   #    state: present
#   #    enabled: true
#   #    controller_host: "https://localhost"
#   #    controller_username: admin
#   #    controller_password: ansible123!
#   #    validate_certs: false

#   - name:  Add Windows Inventory
#     ansible.controller.inventory:
#      name: "Windows Directory Servers"
#      description: "AD Infrastructure"
#      organization: "Default"
#      state: present
#      controller_host: "https://localhost"
#      controller_username: admin
#      controller_password: ansible123!
#      validate_certs: false

#   - name: Add Windows Inventory Host
#     ansible.controller.host:
#      name: "windows"
#      description: "Directory Servers"
#      inventory: "Windows Directory Servers"
#      state: present
#      enabled: true
#      controller_host: "https://localhost"
#      controller_username: admin
#      controller_password: ansible123!
#      validate_certs: false
#      variables:
#        ansible_host: windows

#   - name: Create group with extra vars
#     ansible.controller.group:
#       name: "domain_controllers"
#       inventory: "Windows Directory Servers"
#       hosts:
#         - windows
#       state: present
#       variables:
#         ansible_connection: winrm
#         ansible_port: 5986
#         ansible_winrm_server_cert_validation: ignore
#         ansible_winrm_transport: credssp
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false
        
#   - name: (EXECUTION) Add project
#     ansible.controller.project:
#       name: "Roadshow"
#       description: "Roadshow Content"
#       organization: "Default"
#       scm_type: git
#       scm_url: http://gitea:3000/student/aap25-roadshow-content.git       ##ttps://github.com/nmartins0611/aap25-roadshow-content.git
#       state: present
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: (DECISIONS) Create an AAP Credential
#     ansible.eda.credential:
#       name: "AAP"
#       description: "To execute jobs from EDA"
#       inputs:
#         host: "https://aap.{{ SANDBOX_ID }}.instruqt.io/api/controller/"
#         username: "admin"
#         password: "ansible123!"
#       credential_type_name: "Red Hat Ansible Automation Platform"
#       organization_name: Default
#       controller_host: https://localhost
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

# ###############TEMPLATES###############

#   # - name: Add System Report
#   #   ansible.controller.job_template:
#   #     name: "System Report"
#   #     job_type: "run"
#   #     organization: "Default"
#   #     inventory: "Video Platform Inventory"
#   #     project: "Roadshow"
#   #     playbook: "playbooks/section01/server_re[ort].yml"
#   #     execution_environment: "RHEL EE"
#   #     credentials:
#   #       - "Application Nodes"
#   #     state: "present"
#   #     controller_host: "https://localhost"
#   #     controller_username: admin
#   #     controller_password: ansible123!
#   #     validate_certs: false

#   # - name: Add Windows Setup Template
#   #   ansible.controller.job_template:
#   #     name: "Windows Patching Report"
#   #     job_type: "run"
#   #     organization: "Default"
#   #     inventory: "Windows Directory Servers"
#   #     project: "Roadshow"
#   #     playbook: "playbooks/section01/windows_report.yml"
#   #     execution_environment: "Windows_ee"
#   #     credentials:
#   #       - "Windows Nodes"
#   #     state: "present"
#   #     controller_host: "https://localhost"
#   #     controller_username: admin
#   #     controller_password: ansible123!
#   #     validate_certs: false

#   - name: Add Rhel Report Template
#     ansible.controller.job_template:
#       name: "Application Server Report"
#       job_type: "run"
#       organization: "Default"
#       inventory: "Video Platform Inventory"
#       project: "Roadshow"
#       playbook: "playbooks/section01/rhel_report.yml"
#       execution_environment: "Rhel_ee"
#       credentials:
#         - "Application Nodes"
#       state: "present"
#       survey_enabled: true
#       survey_spec:
#            {
#              "name": "Report Details",
#              "description": "Report components needed",
#              "spec": [
#                {
#     	          "type": "multiplechoice",
#     	          "question_name": "What data are you looking for ?",
#               	"question_description": "Defined data",
#               	"variable": "report_type",
#                 "choices": ["All","Storage Usage","User List","OS Versions"],
#                 "required": true
#                }
#              ]
#            }
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add OSCAP Setup Template
#     ansible.controller.job_template:
#       name: "OpenSCAP Report"
#       job_type: "run"
#       organization: "Default"
#       inventory: "Video Platform Inventory"
#       project: "Roadshow"
#       playbook: "playbooks/section01/rhel_compliance_report.yml"
#       execution_environment: "Rhel_ee"
#       credentials:
#         - "Application Nodes"
#       state: "present"
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add Windows Update Report Template
#     ansible.controller.job_template:
#       name: "Windows Update Report"
#       job_type: "run"
#       organization: "Default"
#       inventory: "Windows Directory Servers"
#       project: "Roadshow"
#       playbook: "playbooks/section01/windows_update_report.yml"
#       execution_environment: "Windows_ee"
#       credentials:
#         - "Windows Nodes"
#       state: "present"
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add RHEL Backup
#     ansible.controller.job_template:
#       name: "Server Backup - XFS/RHEL"
#       job_type: "run"
#       organization: "Default"
#       inventory: "Video Platform Inventory"
#       project: "Roadshow"
#       playbook: "playbooks/section01/xfs_backup.yml"
#       execution_environment: "Rhel_ee"
#       credentials:
#         - "Application Nodes"
#       state: "present"
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add RHEL Backup Check
#     ansible.controller.job_template:
#       name: "Check RHEL Backup"
#       job_type: "run"
#       organization: "Default"
#       inventory: "Video Platform Inventory"
#       project: "Roadshow"
#       playbook: "playbooks/section01/check_backups.yml"
#       execution_environment: "Rhel_ee"
#       credentials:
#         - "Application Nodes"
#       state: "present"
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false


#   - name: Add Windows Backup 
#     ansible.controller.job_template:
#       name: "Server Backup - VSS/Windows"
#       job_type: "run"
#       organization: "Default"
#       inventory: "Windows Directory Servers"
#       project: "Roadshow"
#       playbook: "playbooks/section01/vss_windows.yml"
#       execution_environment: "Windows_ee"
#       credentials:
#         - "Windows Nodes"
#       state: "present"
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false

#   - name: Add Windows Backup Check
#     ansible.controller.job_template:
#       name: "Check Windows Backups"
#       job_type: "run"
#       organization: "Default"
#       inventory: "Windows Directory Servers"
#       project: "Roadshow"
#       playbook: "playbooks/section01/check_windowsvss.yml"
#       execution_environment: "Windows_ee"
#       credentials:
#         - "Windows Nodes"
#       state: "present"
#       controller_host: "https://localhost"
#       controller_username: admin
#       controller_password: ansible123!
#       validate_certs: false




# ...
# EOF

# # chown files
# sudo chown rhel:rhel /tmp/setup.yml
# sudo chown rhel:rhel /tmp/inventory
# sudo chown rhel:rhel /tmp/git-setup.yml

# # execute above playbook
# #su - root -c 'ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-2.5-2/collections/:/home/rhel/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/git-setup.yml'

# su - rhel -c 'ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-2.5-2/collections/:/home/rhel/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml'




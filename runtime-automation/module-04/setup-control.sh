#!/bin/bash

# Create a playbook for the user to execute which will collect nodes information
tee /tmp/collect-node-info.yml << EOF
---
- name: get node facts for SNOW
  hosts: nodes
  vars:
    node_info: []

  tasks:

  - name: Collect inventory facts
    ansible.builtin.set_stats:
      data:
        node_info: "{{ node_info + [{'hostname': ansible_facts['nodename'], 'default_ip': ansible_facts['default_ipv4']['address'], 'default_mac': ansible_facts['default_ipv4']['macaddress'], 'vendor': ansible_facts['product_name'] }] }}"

EOF

# chown above file
sudo chown rhel:rhel /tmp/collect-node-info.yml

# Create a playbook for the user to execute which will create/update CIs
tee /tmp/create-update-config-items.yml << EOF
---
- name: Automate SNOW 
  hosts: localhost
  connection: local
  collections:
    - servicenow.itsm
  vars:
    demo_username: "{{ lookup('env', 'SN_USERNAME') }}"

  tasks:
  - name: Create/update configuration item
    servicenow.itsm.configuration_item:
      name: "{{ item.hostname }}-{{ demo_username }}"
      assigned_to: "{{ demo_username }}"
      ip_address: "{{ item.default_ip }}"
      mac_address: "{{ item.default_mac }}"
      environment: test
      other:
        sys_class_name: cmdb_ci_linux_server
    loop: "{{ node_info }}"
    register: configuration_item

  - name: debug
    debug:
      msg: "{{ configuration_item }}"

EOF

# chown above file
sudo chown rhel:rhel /tmp/create-update-config-items.yml

# Write a new playbook to create a template from above playbook
tee /tmp/template-create-module04.yml << EOF
---
- name: Create job template for collect node info
  hosts: localhost
  connection: local
  collections:
    - ansible.controller

  tasks:
  - name: Post collect-nodes job template
    job_template:
      name: "4.1 - Collect node information (collect-node-info.yml)"
      job_type: "run"
      organization: "Default"
      inventory: "rhel inventory"
      project: "ServiceNow - admin"
      playbook: "student_project/collect-node-info.yml"
      execution_environment: "ServiceNow EE"
      credentials:
        - "rhel credential"
      state: "present"
      ask_variables_on_launch: false
      use_fact_cache: true
      controller_host: "https://localhost"
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false

  - name: Post create/update cmdb job template
    job_template:
      name: "4.2 - Create/update configuration items (create-update-config-items.yml)"
      job_type: "run"
      organization: "Default"
      inventory: "Demo Inventory"
      project: "ServiceNow - admin"
      playbook: "student_project/create-update-config-items.yml"
      execution_environment: "ServiceNow EE"
      credentials:
        - "ServiceNow Credential"
      state: "present"
      ask_variables_on_launch: false
      controller_host: "https://localhost"
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false

  - name: Create a workflow job template with schema in template
    awx.awx.workflow_job_template:
      name: "4.0 - Query node info and update CMDB (multiple job templates)"
      inventory: Demo Inventory
      controller_host: "https://localhost"
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false
      schema:
        - identifier: query-inventory
          unified_job_template:
            organization:
              name: Default
            name: "4.1 - Collect node information (collect-node-info.yml)"
            type: job_template
          credentials: []
          related:
            success_nodes:
              - identifier: update-cmdb
            failure_nodes: []
            always_nodes: []
            credentials: []
        - identifier: update-cmdb
          unified_job_template:
            organization:
              name: Default
            name: "4.2 - Create/update configuration items (create-update-config-items.yml)"
            type: job_template
          credentials: []
          related:
            success_nodes: []
            failure_nodes: []
            always_nodes: []
            credentials: []
    register: result

EOF

# chown above file
sudo chown rhel:rhel /tmp/template-create-module04.yml

# Run the playbook with the correct collections path environment variable and only existing paths
ANSIBLE_COLLECTIONS_PATH="/root/.ansible/collections/ansible_collections/" \
ansible-playbook -i /tmp/inventory /tmp/template-create-module04.yml
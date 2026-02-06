#!/bin/bash

# Create a playbook for the user to execute which will collect nodes information
tee /tmp/collect-node-info.yml << EOF
---
- name: get node facts for SNOW
  hosts: nodes
  gather_facts: true

  tasks:
  - name: Build node info list
    ansible.builtin.set_fact:
      node_info: >-
        {{
          node_info | default([]) + [{
            'hostname': ansible_facts['hostname'],
            'default_ip': ansible_facts['default_ipv4']['address'],
            'default_mac': ansible_facts['default_ipv4']['macaddress'],
            'vendor': ansible_facts['product_name'],
            'cpu': ansible_facts['processor_vcpus'],
            'memory_mb': ansible_facts['memtotal_mb'],
            'os': ansible_facts['distribution'],
            'os_version': ansible_facts['distribution_version'],
            'architecture': ansible_facts['architecture']
          }]
        }

  - name: Save node info to file
    copy:
      content: "{{ node_info | to_json }}"
      dest: /tmp/node_info.json
    delegate_to: localhost
    run_once: true
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
    node_info: "{{ lookup('file', '/tmp/node_info.json') | from_json }}"

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
        cpu_core_count: "{{ item.cpu }}"
        ram: "{{ item.memory_mb }}"
        os: "{{ item.os }}"
        os_version: "{{ item.os_version }}"
        architecture: "{{ item.architecture }}"
        short_description: >-
          {{ item.cpu }} CPUs, {{ item.memory_mb }}MB RAM,
          {{ item.os }} {{ item.os_version }} ({{ item.architecture }})

    loop: "{{ node_info }}"
    register: configuration_item

  - debug:
      msg: "Created/updated CI {{ item.record.name }}"
    loop: "{{ configuration_item.results }}"

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
    ansible.controller.workflow_job_template:
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
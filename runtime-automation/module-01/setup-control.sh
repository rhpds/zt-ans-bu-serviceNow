#!/bin/bash

# Write a new playbook to create a job template from the previous playbook
tee /tmp/template-create.yml << EOF
---
- name: Create job template and copy file to code-server
  hosts: localhost, code-server
  gather_facts: false
  collections:
    - ansible.controller

  tasks:
  - name: Post create-incident job template
    ansible.controller.job_template:
      name: "1 - Create incident (incident-create.yml)"
      job_type: "run"
      organization: "Default"
      inventory: "Demo Inventory"
      project: "ServiceNow - admin"
      playbook: "student_project/incident-create.yml"
      execution_environment: "ServiceNow EE"
      use_fact_cache: false
      credentials:
        - "ServiceNow Credential"
      state: "present"
      controller_host: "https://localhost"
      controller_username: admin
      controller_password: ansible123!
      validate_certs: false
    delegate_to: localhost
    run_once: true

  - name: Ensure /home/coder exists
    ansible.builtin.file:
      path: /home/coder
      state: directory
      mode: '0755'
    when: inventory_hostname == "code-server"

  - name: Copy incident-create.yml to code-server
    ansible.builtin.copy:
      src: "/home/rhel/aap/controller/data/projects/_8__servicenow_admin/student_project/incident-create.yml"
      dest: "/home/coder/incident-create.yml"
      mode: '0644'
    when: inventory_hostname == "code-server"
EOF

# chown above file
chown rhel:rhel /tmp/template-create.yml

ANSIBLE_COLLECTIONS_PATH="/root/.ansible/collections/ansible_collections/" \
ansible-playbook -i /tmp/inventory /tmp/template-create.yml

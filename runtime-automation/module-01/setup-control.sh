#!/bin/bash

# make challenge dir
mkdir -p /home/rhel/challenge-1

# Write a new playbook to create a job template from the previous playbook
tee /home/rhel/challenge-1/template-create.yml << EOF
---
- name: Create job template for create-incident
  hosts: localhost
  connection: local
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
          - "ServiceNow"
        state: "present"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
EOF

# chown above file
chown rhel:rhel /home/rhel/challenge-1/template-create.yml

ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /home/rhel/challenge-1/template-create.yml

# Write a new playbook to grant the student access to the job template
tee /home/rhel/challenge-1/role-update.yml << EOF
---
- name: Grant 'student' execute access to job template
  hosts: localhost
  connection: local
  gather_facts: false
  collections:
    - ansible.controller

  tasks:

    - name: Add execute role for student
      role:
        user: student
        role: execute
        job_templates:
          - "1 - Create incident (incident-create.yml)"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
EOF

# chown above file
chown rhel:rhel /home/rhel/challenge-1/role-update.yml

# Execute the playbook to assign role access
ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /home/rhel/challenge-1/role-update.yml

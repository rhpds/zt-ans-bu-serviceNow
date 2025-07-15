#!/bin/bash

# Pull the servicenow EE
su - $USER -c 'podman pull quay.io/acme_corp/servicenow-ee:latest'

# Update ansible extension
su - $USER -c 'code-server --install-extension redhat.ansible --force'

# set vscode default settings
su - $USER -c 'cat >/home/$USER/.local/share/code-server/User/settings.json <<EOL
{
    "git.ignoreLegacyWarning": true,
    "window.menuBarVisibility": "visible",
    "git.enableSmartCommit": true,
    "workbench.tips.enabled": false,
    "workbench.startupEditor": "readme",
    "telemetry.enableTelemetry": false,
    "search.smartCase": true,
    "git.confirmSync": false,
    "workbench.colorTheme": "Solarized Dark",
    "update.showReleaseNotes": false,
    "update.mode": "none",
    "ansible.ansibleLint.enabled": true,
    "ansible.ansible.useFullyQualifiedCollectionNames": true,
    "redhat.telemetry.enabled": true,
    "markdown.preview.doubleClickToSwitchToEditor": false,
    "files.exclude": {
        "**/.*": true
    },
    "ansible.executionEnvironment.enabled": true,
    "ansible.executionEnvironment.image": "quay.io/acme_corp/servicenow-ee:latest",
    "ansibleServer.trace.server": "verbose",
    "files.associations": {
        "*.yml": "ansible"
    }
}

EOL
cat /home/$USER/.local/share/code-server/User/settings.json'

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
      - SN_USERNAME
      - SN_PASSWORD
      - INSTRUQT_PARTICIPANT_ID
  playbook-artifact:
    enable: true
    save-as: "{playbook_dir}/artifacts/{playbook_name}-artifact-{time_stamp}.json"
  logging:
    append: true
    file: 'artifacts/ansible-navigator.log'
    level: warning
  editor:
    command: code-server {filename}
    console: false

EOL
cat /home/rhel/servicenow_project/ansible-navigator.yml'
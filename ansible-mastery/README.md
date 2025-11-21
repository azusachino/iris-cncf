# Ansible Mastery: Configuration Management & Automation

Comprehensive guide to mastering Ansible for infrastructure automation and configuration management.

## 🎯 Learning Objectives

- Master Ansible fundamentals (playbooks, roles, inventory)
- Automate server configuration and deployment
- Manage multi-cloud infrastructure
- Implement best practices and security
- Create reusable roles and collections
- Integrate with CI/CD pipelines
- Advanced patterns (dynamic inventory, delegation, blocks)

## 📚 Repository Structure

```
ansible-mastery/
├── basics/              # Ansible fundamentals
│   ├── ad-hoc/         # Ad-hoc commands
│   ├── inventory/      # Inventory management
│   ├── variables/      # Variable usage
│   └── facts/          # Gathering facts
│
├── playbooks/           # Playbook examples
│   ├── web-server/     # Web server setup
│   ├── database/       # Database configuration
│   ├── kubernetes/     # K8s cluster setup
│   └── cloud/          # Cloud resource management
│
├── roles/               # Reusable roles
│   ├── common/         # Common server setup
│   ├── nginx/          # Nginx web server
│   ├── docker/         # Docker installation
│   ├── k8s/            # Kubernetes components
│   └── monitoring/     # Prometheus, Grafana
│
├── advanced/            # Advanced topics
│   ├── dynamic-inventory/  # AWS, Azure, GCP inventory
│   ├── vault/          # Ansible Vault secrets
│   ├── custom-modules/ # Custom module development
│   ├── plugins/        # Custom plugins
│   └── collections/    # Ansible collections
│
└── real-world/          # Production scenarios
    ├── multi-tier-app/ # Complete application deployment
    ├── zero-downtime/  # Rolling updates
    ├── disaster-recovery/ # Backup and restore
    └── compliance/     # Security hardening
```

## 🚀 Quick Start

### Installation

```bash
# Install Ansible
# macOS
brew install ansible

# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# RHEL/CentOS
sudo yum install ansible

# Using pip (any OS)
pip install ansible

# Verify installation
ansible --version
```

### Basic Concepts

**Inventory (hosts):**
```ini
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com ansible_host=10.0.1.10

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

**Simple Playbook:**
```yaml
---
- name: Configure web servers
  hosts: webservers
  become: yes

  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes
```

**Run Playbook:**
```bash
ansible-playbook -i inventory playbook.yml
```

## 📖 Learning Path

### Week 1: Ansible Fundamentals
- Installation and configuration
- Inventory management
- Ad-hoc commands
- Basic playbooks
- Variables and facts
- Conditionals and loops

### Week 2: Roles and Structure
- Role structure and organization
- Role dependencies
- Ansible Galaxy
- Best practices for reusability
- Testing roles with Molecule

### Week 3: Advanced Playbooks
- Handlers and notifications
- Templates (Jinja2)
- Blocks, rescue, always
- Delegation and local actions
- Tags and task organization

### Week 4: Cloud Automation
- AWS module usage
- Azure resource management
- GCP automation
- Dynamic inventory
- Cloud-agnostic playbooks

### Week 5: Kubernetes Automation
- K8s cluster deployment
- Application deployment
- Helm chart management
- Monitoring stack setup

### Week 6: Security & Secrets
- Ansible Vault
- SSH key management
- Security hardening playbooks
- Compliance automation (CIS benchmarks)

### Week 7: CI/CD Integration
- GitLab CI/Ansible
- GitHub Actions integration
- Jenkins integration
- AWX/Ansible Tower

### Week 8: Production Patterns
- Zero-downtime deployments
- Rolling updates
- Blue-green deployments
- Disaster recovery
- Multi-environment management

## 💡 Key Concepts

### 1. Inventory

**Static Inventory:**
```ini
[production:children]
webservers
databases

[webservers]
web[01:05].prod.example.com

[databases]
db[01:03].prod.example.com

[production:vars]
env=production
datacenter=us-east-1
```

**Dynamic Inventory (AWS):**
```bash
# Install boto3
pip install boto3

# Use AWS EC2 plugin
ansible-inventory -i aws_ec2.yml --graph
```

**aws_ec2.yml:**
```yaml
plugin: aws_ec2
regions:
  - us-east-1
  - us-west-2
filters:
  tag:Environment: production
keyed_groups:
  - key: tags.Role
    prefix: role
  - key: placement.availability_zone
    prefix: az
```

### 2. Variables

**Variable Precedence (lowest to highest):**
1. command line values (e.g. -u user)
2. role defaults
3. inventory file or script group vars
4. inventory group_vars/all
5. playbook group_vars/all
6. inventory group_vars/*
7. playbook group_vars/*
8. inventory file or script host vars
9. inventory host_vars/*
10. playbook host_vars/*
11. host facts / cached set_facts
12. play vars
13. play vars_prompt
14. play vars_files
15. role vars (defined in role/vars/main.yml)
16. block vars (only for tasks in block)
17. task vars (only for the task)
18. include_vars
19. set_facts / registered vars
20. role (and include_role) params
21. include params
22. extra vars (-e in the command line)

**group_vars/all.yml:**
```yaml
---
ntp_server: pool.ntp.org
timezone: UTC
admin_email: admin@example.com
```

**host_vars/web1.yml:**
```yaml
---
server_role: frontend
max_connections: 1000
```

### 3. Playbook Structure

```yaml
---
- name: Deploy web application
  hosts: webservers
  become: yes
  gather_facts: yes

  vars:
    app_port: 8080
    app_name: myapp

  vars_files:
    - vars/common.yml
    - vars/{{ env }}.yml

  pre_tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

  roles:
    - common
    - nginx
    - { role: app, app_version: "1.2.3" }

  tasks:
    - name: Deploy application
      copy:
        src: "{{ app_name }}.jar"
        dest: "/opt/{{ app_name }}/"
        mode: 0755
      notify: restart app

  post_tasks:
    - name: Verify application
      uri:
        url: "http://localhost:{{ app_port }}/health"
        status_code: 200

  handlers:
    - name: restart app
      service:
        name: "{{ app_name }}"
        state: restarted
```

### 4. Roles

**Role Structure:**
```
roles/nginx/
├── defaults/
│   └── main.yml       # Default variables (lowest precedence)
├── files/
│   └── nginx.conf     # Static files to copy
├── handlers/
│   └── main.yml       # Handlers (triggered by notify)
├── meta/
│   └── main.yml       # Role dependencies and metadata
├── tasks/
│   └── main.yml       # Main task list
├── templates/
│   └── vhost.j2       # Jinja2 templates
├── tests/
│   └── test.yml       # Test playbook
└── vars/
    └── main.yml       # Role variables (high precedence)
```

**roles/nginx/tasks/main.yml:**
```yaml
---
- name: Install nginx
  apt:
    name: nginx
    state: present
  when: ansible_os_family == "Debian"

- name: Install nginx
  yum:
    name: nginx
    state: present
  when: ansible_os_family == "RedHat"

- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    validate: nginx -t -c %s
  notify: reload nginx

- name: Ensure nginx is running
  service:
    name: nginx
    state: started
    enabled: yes
```

**roles/nginx/handlers/main.yml:**
```yaml
---
- name: reload nginx
  service:
    name: nginx
    state: reloaded

- name: restart nginx
  service:
    name: nginx
    state: restarted
```

### 5. Templates (Jinja2)

**template.j2:**
```jinja
# Generated by Ansible - DO NOT EDIT MANUALLY
# Environment: {{ env }}
# Date: {{ ansible_date_time.iso8601 }}

server {
    listen {{ nginx_port | default(80) }};
    server_name {{ server_name }};

    {% if ssl_enabled %}
    listen 443 ssl;
    ssl_certificate {{ ssl_cert_path }};
    ssl_certificate_key {{ ssl_key_path }};
    {% endif %}

    location / {
        proxy_pass http://{{ backend_host }}:{{ backend_port }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    {% for location in custom_locations %}
    location {{ location.path }} {
        {{ location.config }}
    }
    {% endfor %}
}
```

### 6. Advanced Features

**Blocks with Error Handling:**
```yaml
- name: Handle errors gracefully
  block:
    - name: Attempt risky operation
      command: /usr/bin/risky-command
      register: result

    - name: Process result
      debug:
        msg: "Success: {{ result.stdout }}"

  rescue:
    - name: Handle error
      debug:
        msg: "Operation failed, rolling back"

    - name: Rollback action
      command: /usr/bin/rollback

  always:
    - name: Cleanup
      file:
        path: /tmp/temp-file
        state: absent
```

**Loops:**
```yaml
# Simple loop
- name: Install packages
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - postgresql
    - redis

# Loop with dict
- name: Create users
  user:
    name: "{{ item.name }}"
    groups: "{{ item.groups }}"
    state: present
  loop:
    - { name: 'john', groups: 'developers' }
    - { name: 'jane', groups: 'admins' }

# Loop with dict keys
- name: Create directories
  file:
    path: "{{ item.key }}"
    owner: "{{ item.value.owner }}"
    mode: "{{ item.value.mode }}"
    state: directory
  loop: "{{ directories | dict2items }}"
  vars:
    directories:
      /opt/app:
        owner: www-data
        mode: '0755'
      /var/log/app:
        owner: www-data
        mode: '0750'
```

**Delegation:**
```yaml
- name: Deploy to web servers from deployment server
  hosts: webservers
  tasks:
    - name: Build application
      command: mvn package
      delegate_to: build-server
      run_once: yes

    - name: Deploy artifact
      copy:
        src: /tmp/app.jar
        dest: /opt/app/
      delegate_to: "{{ inventory_hostname }}"
```

## 🔒 Security Best Practices

### Ansible Vault

**Create encrypted file:**
```bash
ansible-vault create secrets.yml
```

**Edit encrypted file:**
```bash
ansible-vault edit secrets.yml
```

**Encrypt existing file:**
```bash
ansible-vault encrypt vars/production.yml
```

**Run playbook with vault:**
```bash
ansible-playbook playbook.yml --ask-vault-pass
# or
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass
```

**secrets.yml (encrypted):**
```yaml
---
db_password: "super_secret_password"
api_key: "sk-1234567890abcdef"
```

### Security Hardening Playbook

```yaml
---
- name: Security hardening
  hosts: all
  become: yes

  tasks:
    - name: Update all packages
      apt:
        upgrade: dist
        update_cache: yes

    - name: Configure firewall
      ufw:
        rule: "{{ item.rule }}"
        port: "{{ item.port }}"
        proto: "{{ item.proto }}"
      loop:
        - { rule: 'allow', port: '22', proto: 'tcp' }
        - { rule: 'allow', port: '80', proto: 'tcp' }
        - { rule: 'allow', port: '443', proto: 'tcp' }

    - name: Enable firewall
      ufw:
        state: enabled

    - name: Disable root login
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PermitRootLogin'
        line: 'PermitRootLogin no'
      notify: restart sshd

    - name: Disable password authentication
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PasswordAuthentication'
        line: 'PasswordAuthentication no'
      notify: restart sshd

    - name: Install fail2ban
      apt:
        name: fail2ban
        state: present

  handlers:
    - name: restart sshd
      service:
        name: sshd
        state: restarted
```

## 🧪 Testing with Molecule

**Install Molecule:**
```bash
pip install molecule molecule-docker
```

**Initialize role with Molecule:**
```bash
molecule init role my-role --driver-name docker
```

**Test role:**
```bash
molecule test
```

## 📊 AWX / Ansible Tower

Benefits of AWX (open-source) / Tower (enterprise):
- Web UI for playbook execution
- RBAC and credential management
- Job scheduling
- REST API
- Inventory management
- Notifications

## 📝 Best Practices Checklist

- [ ] Use version control (Git)
- [ ] Organize with roles
- [ ] Use Ansible Vault for secrets
- [ ] Pin versions in requirements.yml
- [ ] Use tags for selective execution
- [ ] Implement idempotency
- [ ] Use check mode for dry runs
- [ ] Use handlers for service restarts
- [ ] Leverage group_vars and host_vars
- [ ] Use templates instead of multiple files
- [ ] Test with Molecule
- [ ] Document playbooks and roles
- [ ] Use meaningful names
- [ ] Avoid shell/command when module exists
- [ ] Use changed_when and failed_when
- [ ] Implement error handling
- [ ] Use --syntax-check and --check
- [ ] Set connection limits (forks)

## 🔗 Resources

- **Official Docs**: https://docs.ansible.com/
- **Ansible Galaxy**: https://galaxy.ansible.com/
- **Best Practices**: https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html
- **Molecule**: https://molecule.readthedocs.io/

Start with basic playbooks, build reusable roles, then tackle complex multi-tier deployments!

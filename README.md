# OpenLab

OpenLab is an automation platform designed to rapidly provision, manage, and tear down isolated lab environments for custom courses and training sessions. It streamlines the deployment of virtualized desktops and user environments on AWS, making it easy for instructors and administrators to deliver hands-on experiences at scale.

The core integrates three well known technologies:

- **Terraform** for automated, reproducible AWS infrastructure lifecycle management;
- **Ansible** for seamless user and credential management within the Guacamole remote desktop gateway;
- **Guacamole** for browser-based desktop virtualization, providing students with secure, remote access to lab machines.

## Lab infrastructure

![Topology](diagram/topology.svg)

## Prerequisites

- An AWS account with administration privileges
- An access key id and a secret access key. Create the file `terraform/.aws/credentials` like the following:

  ```plaintext
  [default]
  aws_access_key_id=<replace_with_your_access_key_id>
  aws_secret_access_key=<replace_with_your_secret_access_key>
  ```

- Two pre-configured Amazon Machine Images (AMIs):
  - one for Guacamole system with the associated key pair for SSH access used by Ansible;
  - one for lab user instances.

- Terraform and Ansible CLIs installed locally

- `scicore.guacamole` Ansible module installed:

  ```sh
  ansible-galaxy collection install scicore.guacamole
  ```

- A valid email to use for letsencrypt and get a valid certificate for the lab hostname.

## Provision your first lab

1. Create a lab configuration file like the one shown as example:

   ```yaml
   lab:
     name: mylab
     region: eu-south-1
     guacadmin_password: changeme
     letsencrypt:
       email: jsmith@acme.com
     users:
       - alice
       - bob
     instances:
       - name: vm01
         ami: ami-0123456789cafebabe # should be a valid AMI
         instance_type: t3.medium
         user: student # should be the already configured user in the AMI
         password: student # should be the already configured user in the AMI
   ```

2. Use `ansible-playbook` to create the environment.

   ```sh
   ansible-playbook playbook.yaml -e @lab.yaml -e action=create`
   ```

## Destroy the lab

```sh
ansible-playbook playbook.yaml -e @lab.yaml -e action=destroy`
```

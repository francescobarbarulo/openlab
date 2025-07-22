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

## Use the CLI

The orchestration between Terraform and Ansible is done by the `openlab` CLI generated with [Bashly](https://bashly.dev/).
The CLI provides simple commands to create, list, start, stop, and delete labs, abstracting away the complexity of the underlying tools.

1. Create a link to `/usr/local/bin` in order to use it globally.

   ```sh
   sudo ln bashly/openlab /usr/local/bin/openlab
   ```

2. Create a `terraform.tfvars.json` file similar to the following in terraform folder. Set variables properly for your use case.

   ```json
   {
     "region": "eu-south-1",
     "postgres_user": "postgres",
     "postgres_password": "changeme",
     "postgres_db": "guacamole_db",
     "acme_email": "acme@openlab.io",
     "guacadmin_password": "changeme",
     "guacamole_instance_type": "t3.medium",
     "guacamole_ssh_key": "KeyPairMilan",
     "instances": [
       {
         "ami": "ami-06f70f6789ba21dc7",
         "instance_type": "t3.medium",
         "user": "student",
         "password": "student"
       },
       {
         "ami": "ami-06f70f6789ba21dc7",
         "instance_type": "t3.medium",
         "user": "student",
         "password": "student"
       }
     ],
     "lab_users": ["user01", "user02"]
   }
   ```

3. Use `openlab create <name>` to create a new lab environment.

### Generate the openlab CLI

1. Install Bashly

2. Run the following commands to generate the `openlab` CLI (in this case bashly is executed in a Docker container) .

   ```sh
   alias bashly='docker run --rm -it --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly'
   # Generate the bash script
   cd bashly && bashly generate && cd ..
   # (Optional) Create a link to use it globally
   sudo ln bashly/openlab /usr/local/bin/openlab
   ```

# OpenLab

The OpenLab project aims to automate the instantiation of labs for custom courses.
The core leverages three well known products:

- _terraform_ for resource lifecycle management on AWS;
- _ansible_ for users management on guacamole;
- _guacamole_ for desktop virtualization.

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

## Generate cli

```sh
alias bashly='docker run --rm -it --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly'
cd bashly && bashly generate && cd ..
sudo ln lab /usr/local/bin/lab
```

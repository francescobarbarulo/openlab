variable "env" {
  description = "Environment"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "Allowed values: dev, prod"
  }
}

variable "region" {
  description = "AWS region where the lab environment will be instantiated"
  type = string
}

variable "guacamole_ami" {
  description = "AMI to be used for guacamole instance. It must exist before provisioning."
  type = string
  default = "ami-040f47e4ddbe2ee13" # pointing to ubuntu 24.04 AMI
}

variable "guacamole_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "guacamole_ssh_key" {
  description = "Name of SSH key pair stored in AWS. Use it only for debugging operations. The username depends on the AMI used."
  type = string
}

variable "lab_users" {
  description = "Users' name"
  type        = list(string)
}

variable "instance_state" {
  description = "Instance state (running | stopped)"
  type        = string
  default     = "running"

  validation {
    condition     = contains(["running", "stopped"], var.instance_state)
    error_message = "Allowed values: running, stopped"
  }
}

variable "instance_ami" {
  description = "AMI to be used for user instances. It must exist before provisioning."
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "connection_username" {
  description = "Username for the guacamole RDP connection. Depends on pre-configured lab user instance."
  type        = string
}

variable "connection_password" {
  description = "Password for the guacamole RDP connection. Depends on pre-configured lab user instance."
  type        = string
  sensitive   = true
}

variable "postgres_user" {
  description = "Postgres administrator username"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "Postgres administrator password"
  type        = string
  sensitive   = true
}

variable "postgres_db" {
  description = "Postgres database"
  type        = string
  sensitive   = true
}

variable "acme_letsencrypt_endpoint" {
  description = "ACME v2 Let's Encrypt endpoint for frontend certificate"
  type        = map(string)
  default = {
    dev  = "https://acme-staging-v02.api.letsencrypt.org/directory"
    prod = "https://acme-v02.api.letsencrypt.org/directory"
  }
}

variable "acme_email" {
  type = string
}

variable "guacadmin_password" {
  type      = string
  sensitive = true
}

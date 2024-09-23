variable "lab_users_count" {
  description = "Number of lab's users"
  type        = number
}

variable "instance_ami" {
  description = "AMI to be used for user instances. It must exist before provioning."
  type        = string
  default     = "ami-06f70f6789ba21dc7"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "connection_username" {
  description = "Username for the guacamole RDP connection. Depends on pre-configured instance."
  type        = string
}

variable "connection_password" {
  description = "Password for the guacamole RDP connection. Depends on pre-configured instance."
  type        = string
  sensitive   = true
}

variable "guacadmin_password" {
  description = "Password of guacadmin user"
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
  description = "ACME v2 Let's eEcrypt endpoint for frontend certificate"
  type        = map(string)
  default = {
    staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
    prod    = "https://acme-v02.api.letsencrypt.org/directory"
  }
}

variable "acme_email" {
  type = string
}

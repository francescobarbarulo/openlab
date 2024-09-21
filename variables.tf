variable "lab_users_count" {
  type    = number
  default = 2
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

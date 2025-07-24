output "lab_url" {
  description = "Guacamole URL"
  value       = format("https://guacamole.%s.sslip.io", aws_eip.frontend_ip.public_ip)
}

output "state" {
  description = "Lab state"
  value       = aws_ec2_instance_state.guacamole_frontend_instance_state.state
}

output "instances" {
  description = "Lab VMs"
  value       = local.instances
}


output "users" {
  value = [for user in var.lab_users : user]
}

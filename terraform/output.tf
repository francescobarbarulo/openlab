output "guacamole_public_ip" {
  value = aws_eip.frontend_ip.public_ip
}

output "state" {
  description = "Lab state"
  value       = aws_ec2_instance_state.guacamole_frontend_instance_state.state
}

output "instances" {
  description = "Lab VMs"
  value       = local.user_instances
}

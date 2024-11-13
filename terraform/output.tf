output "hostname" {
  description = "Guacamole hostname"
  value       = format("guacamole.%s.sslip.io", aws_eip.frontend_ip.public_ip)
}

output "state" {
  description = "Lab state"
  value       = aws_ec2_instance_state.guacamole_frontend_instance_state.state
}

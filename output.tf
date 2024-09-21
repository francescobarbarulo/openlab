output "hostname" {
  description = "Guacamole hostname"
  value       = format("guacamole.%s.sslip.io", aws_eip.frontend_ip.public_ip)
}

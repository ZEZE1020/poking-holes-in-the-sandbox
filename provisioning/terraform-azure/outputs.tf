output "public_ip_address" {
  description = "Public IP address of the shared workshop host."
  value       = azurerm_public_ip.workshop.ip_address
}

output "ssh_command" {
  description = "SSH command for the shared workshop host."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.workshop.ip_address}"
}

output "terminal_urls" {
  description = "HTTPS URLs for the 20 participant ttyd terminals."
  value = [
    for port in local.terminal_ports :
    "https://${azurerm_public_ip.workshop.ip_address}:${port}"
  ]
}

output "terminal_users" {
  description = "Linux users mapped to the terminal URLs in terminal_urls order."
  value       = local.terminal_users
}

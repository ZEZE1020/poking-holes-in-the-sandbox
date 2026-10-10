output "terminal_urls" {
  description = "Browser URLs for each attendee node's ttyd terminal."
  value       = [for instance in google_compute_instance.node : "http://${instance.network_interface[0].access_config[0].nat_ip}:7681"]
}

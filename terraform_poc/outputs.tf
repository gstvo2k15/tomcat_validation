output "rhel8_hostname" {
  description = "Hostname de la máquina RHEL 8"
  value       = cibcloud_tomcat_vdc.rhel8.hostname
}

output "rhel9_hostname" {
  description = "Hostname de la máquina RHEL 9"
  value       = cibcloud_tomcat_vdc.rhel9.hostname
}
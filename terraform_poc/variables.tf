variable "tower_url" {
  description = "URL de AAP / Ansible Tower"
  type        = string
}

variable "tower_token" {
  description = "Token de acceso a la API de AAP/Tower"
  type        = string
  sensitive   = true
}

variable "tower_inventory_id" {
  description = "ID del Inventory de AAP/Tower"
  type        = number
}

variable "tower_group_id" {
  description = "ID del grupo tomcat_lab en AAP/Tower"
  type        = number
}

variable "tower_job_template_id" {
  description = "ID del Job Template que ejecuta site.yml"
  type        = number
}

variable "tomcat_jdk_choice" {
  description = "Valor enviado al survey del Job Template"
  type        = string
}
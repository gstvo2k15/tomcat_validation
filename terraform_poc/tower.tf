resource "terraform_data" "run_tomcat_validation" {

  depends_on = [
    cibcloud_tomcat_vdc.rhel8,
    cibcloud_tomcat_vdc.rhel9
  ]

  triggers_replace = [
    cibcloud_tomcat_vdc.rhel8.hostname,
    cibcloud_tomcat_vdc.rhel9.hostname,
    var.tomcat_jdk_choice
  ]

  provisioner "local-exec" {

    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      "${path.module}/scripts/tower_launch.sh" \
        "${var.tower_url}" \
        "${var.tower_token}" \
        "${var.tower_inventory_id}" \
        "${var.tower_group_id}" \
        "${var.tower_job_template_id}" \
        "${cibcloud_tomcat_vdc.rhel8.hostname}" \
        "${cibcloud_tomcat_vdc.rhel9.hostname}" \
        "${var.tomcat_jdk_choice}"
    EOT
  }
}
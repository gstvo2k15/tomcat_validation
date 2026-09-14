## How itegrate ansible code now

```bash
terraform-tomcat/
├── terraform/
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── ansible/
│   ├── site.yml
│   ├── inventory/
│   │   └── generated.yml
│   └── roles/
│       └── tomcat_validation/
│           ├── defaults/
│           ├── tasks/
│           ├── templates/
│           └── meta/
│
└── .gitignore
```


`outputs.tf`
```hcl
output "ansible_hostnames" {
  value = [
    cibcloud_tomcat_vdc.rhel8.hostname,
    cibcloud_tomcat_vdc.rhel9.hostname
  ]
}
```

```bash

terraform plan -var-file=".tfvars"

terraform apply -var-file=".tfvars"


terraform output -json ansible_hosts




`variables.tf`

```bash
variable "tower_url" {
  description = "URL del controller AAP/Tower"
  type        = string
}

variable "tower_token" {
  description = "Token API de AAP/Tower"
  type        = string
  sensitive   = true
}

variable "tower_inventory_id" {
  description = "ID del inventory de Tower"
  type        = number
}

variable "tower_group_id" {
  description = "ID del grupo tomcat_lab en Tower"
  type        = number
}

variable "tower_job_template_id" {
  description = "ID del Job Template que ejecuta ansible/site.yml"
  type        = number
}

variable "tomcat_jdk_choice" {
  description = "Combinación Tomcat/JDK enviada al survey del Job Template"
  type        = string
}
```

`terraform.tfvars`

```bash
tower_url             = "https://tower.example.internal"
tower_inventory_id    = 20
tower_group_id        = 35
tower_job_template_id = 117

tomcat_jdk_choice = "Tomcat10 - JDK17"

tower_token = "TOKEN_AAP"
```






`tower.tf`

```bash
resource "terraform_data" "tower_host_rhel8" {

  triggers_replace = [
    cibcloud_tomcat_vdc.rhel8.hostname
  ]

  depends_on = [
    cibcloud_tomcat_vdc.rhel8
  ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]

    command = <<-EOT
      curl --fail --silent --show-error \
        -X POST \
        -H "Authorization: Bearer ${var.tower_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "${cibcloud_tomcat_vdc.rhel8.hostname}",
          "inventory": ${var.tower_inventory_id},
          "enabled": true,
          "variables": "expected_rhel_major: \"8\""
        }' \
        "${var.tower_url}/api/v2/hosts/"
    EOT
  }
}


resource "terraform_data" "tower_host_rhel9" {

  triggers_replace = [
    cibcloud_tomcat_vdc.rhel9.hostname
  ]

  depends_on = [
    cibcloud_tomcat_vdc.rhel9
  ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]

    command = <<-EOT
      curl --fail --silent --show-error \
        -X POST \
        -H "Authorization: Bearer ${var.tower_token}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "${cibcloud_tomcat_vdc.rhel9.hostname}",
          "inventory": ${var.tower_inventory_id},
          "enabled": true,
          "variables": "expected_rhel_major: \"9\""
        }' \
        "${var.tower_url}/api/v2/hosts/"
    EOT
  }
}
```







`tower_launch.sh`

```bash
terraform/
├── scripts/
│   └── tower_launch.sh
```

```shell
#!/usr/bin/env bash

set -euo pipefail

TOWER_URL="$1"
TOWER_TOKEN="$2"
INVENTORY_ID="$3"
GROUP_ID="$4"
JOB_TEMPLATE_ID="$5"
RHEL8_HOST="$6"
RHEL9_HOST="$7"
TOMCAT_JDK_CHOICE="$8"

api() {
    curl \
        --fail \
        --silent \
        --show-error \
        -k \
        -H "Authorization: Bearer ${TOWER_TOKEN}" \
        -H "Content-Type: application/json" \
        "$@"
}

create_host() {

    local hostname="$1"
    local rhel_major="$2"

    local response

    response=$(api \
        -X POST \
        -d "{
              \"name\": \"${hostname}\",
              \"inventory\": ${INVENTORY_ID},
              \"enabled\": true,
              \"variables\": \"expected_rhel_major: \\\"${rhel_major}\\\"\"
            }" \
        "${TOWER_URL}/api/v2/hosts/")

    echo "${response}" | jq -r '.id'
}

echo "Creating RHEL8 host in AAP..."
RHEL8_ID=$(create_host "${RHEL8_HOST}" "8")

echo "Creating RHEL9 host in AAP..."
RHEL9_ID=$(create_host "${RHEL9_HOST}" "9")

echo "Adding hosts to tomcat_lab..."

api \
    -X POST \
    -d "{\"id\": ${RHEL8_ID}}" \
    "${TOWER_URL}/api/v2/groups/${GROUP_ID}/hosts/" \
    >/dev/null

api \
    -X POST \
    -d "{\"id\": ${RHEL9_ID}}" \
    "${TOWER_URL}/api/v2/groups/${GROUP_ID}/hosts/" \
    >/dev/null

echo "Launching AAP Job Template..."

response=$(api \
    -X POST \
    -d "{
          \"extra_vars\": {
            \"tomcat_jdk_choice\": \"${TOMCAT_JDK_CHOICE}\"
          }
        }" \
    "${TOWER_URL}/api/v2/job_templates/${JOB_TEMPLATE_ID}/launch/")

JOB_ID=$(echo "${response}" | jq -r '.job')

echo "AAP Job launched: ${JOB_ID}"
```









`tower.tf`

```bash
resource "terraform_data" "run_tomcat_validation" {

  triggers_replace = [
    cibcloud_tomcat_vdc.rhel8.hostname,
    cibcloud_tomcat_vdc.rhel9.hostname,
    var.tomcat_jdk_choice
  ]

  depends_on = [
    cibcloud_tomcat_vdc.rhel8,
    cibcloud_tomcat_vdc.rhel9
  ]

  provisioner "local-exec" {

    interpreter = ["bash", "-c"]

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
```

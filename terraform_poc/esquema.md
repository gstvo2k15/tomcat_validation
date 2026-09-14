tomcat_validation-main/
├── LICENSE
├── README.md
│
├── terraform/
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── tower.tf
│   ├── terraform.tfvars
│   └── scripts/
│       └── tower_launch.sh
│
├── inventory/
│   └── lab.yml
│
├── roles/
│   └── tomcat_validation/
│       ├── defaults/
│       ├── meta/
│       ├── tasks/
│       └── templates/
│
├── site.yml
│
└── tower/
    ├── job_template_notes.md
    └── survey_spec.yml




terraform state show cibcloud_tomcat_vdc.rhel8


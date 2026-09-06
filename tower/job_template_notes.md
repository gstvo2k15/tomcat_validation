# AAP / Tower Job Template

Recommended settings:

- Inventory: inventory synced from `inventory/lab.yml`, or your existing Tower inventory containing the same hosts/vars.
- Project: Git project containing this repository.
- Playbook: `site.yml`.
- Credentials: SSH/machine credential with sudo/become permissions on both lab hosts.
- Privilege escalation: enabled when required by your controller version/credential setup.
- Verbosity: Normal (0).
- Survey: enabled; reproduce `tower/survey_spec.yml`.

The final stdout contains one task named `TOMCAT JDK CERTIFICATION REPORT` whose `msg` is a list of report lines. Tower will still show normal Ansible tasks before it; it does not replace standard job output with a custom report page.

`set_stats` publishes two artifacts:

- `tomcat_certification`: structured result dictionary.
- `tomcat_certification_report`: same final report as a list of lines.

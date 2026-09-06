# Tomcat / JDK certification project for AAP Tower

This project certifies the latest internally packaged Tomcat and JDK RPMs from Artifactory on two RHEL lab hosts.

## Lab inventory

`inventory/lab.yml` declares:

- `eurvxxx01` expected RHEL 8
- `eurvxxx02` expected RHEL 9

The declaration is only an expectation. The role gathers real OS facts and fails if a host does not match its declared RHEL major.

## Survey

Use one single-select survey variable named `tomcat_jdk_choice` with the choices in `tower/survey_spec.yml`.

Supported combinations:

| Tomcat | JDK survey choices |
|---|---|
| Tomcat 9 | 8, 11, 17, 21, 25* |
| Tomcat 10.1 | 11, 17, 21, 25* |
| Tomcat 11 | 17, 21, 25* |

`*` JDK25 is intentionally restricted by local policy to RHEL9. With a JDK25 survey choice, the RHEL8 host is `NOT_APPLICABLE` and RHEL9 is tested.

## Artifactory

Defaults currently assume these repository keys:

- `https://artifactory.test/8`
- `https://artifactory.test/9`

The role queries JFrog's storage file-list endpoint and selects the matching RPM with the newest `lastModified` value.

Before the first real run, verify in `roles/tomcat_validation/defaults/main.yml`:

- `artifactory_base_url`
- `artifactory_repo_by_rhel`
- `tomcat_package_by_major`
- `jdk_package_by_major`
- `tomcat_validation_url`
- `tomcat_service_regex`
- authentication / TLS requirements

## JDK installation

The internal JDK RPM is expected to install Java below:

`/apps/install/java/.../bin/java`

The role discovers the exact installed `JAVA_HOME` using `rpm -ql <jdk-package>` and refuses to continue if no Java executable is found below `/apps/install/java`.

## setenv.sh

The Tomcat RPM must contain a `bin/setenv.sh`. The role discovers it with `rpm -ql` and modifies only:

- `JAVA_HOME`
- `HOME`
- `CATALINA_HOME`

`lineinfile` replaces an existing assignment or inserts it at EOF. Other file contents are preserved. `JAVA_HOME` is backed up before editing. Multiple pre-existing `JAVA_HOME` definitions cause a failure rather than an ambiguous certification.

## systemd service

The role gathers service facts and searches for:

`^tomcat-DEV.*\.service$`

By default exactly one service must match. It does not guess when there are multiple Tomcat DEV units.

The detected service is restarted with systemd. The role does not enable a service that was previously disabled.

## Runtime validation

A successful host certification proves:

1. selected JDK executable runs
2. Tomcat service restarts and becomes `active`
3. systemd reports a non-zero `MainPID`
4. `/proc/<MainPID>/exe` equals `<selected JAVA_HOME>/bin/java`
5. HTTP endpoint returns an accepted response
6. recent Tomcat logs have no configured critical startup errors

The `/proc/<PID>/exe` check is the proof that Tomcat actually booted with the JDK selected by the survey, not merely that `setenv.sh` contains the expected text.

## Tower output

Tower/AAP Controller will show all ordinary Ansible task events. At the end, the second localhost play emits:

`TASK [TOMCAT JDK CERTIFICATION REPORT]`

The `msg` is an array of readable report lines, which renders more cleanly in Controller stdout than one multiline `debug` string.

The same data is published with `set_stats` as job artifacts.

If an applicable host failed, the consolidated report is printed first and then the localhost play intentionally marks the job failed.

## Example CLI run

```bash
ansible-playbook -i inventory/lab.yml site.yml \
  -e 'tomcat_jdk_choice=Tomcat10 - JDK17'
```

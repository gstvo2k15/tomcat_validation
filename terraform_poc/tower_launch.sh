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


echo "Creating RHEL8 host in Tower: ${RHEL8_HOST}"

RHEL8_ID=$(create_host \
    "${RHEL8_HOST}" \
    "8")


echo "Creating RHEL9 host in Tower: ${RHEL9_HOST}"

RHEL9_ID=$(create_host \
    "${RHEL9_HOST}" \
    "9")


echo "Adding ${RHEL8_HOST} to tomcat_lab"

api \
    -X POST \
    -d "{
          \"id\": ${RHEL8_ID}
        }" \
    "${TOWER_URL}/api/v2/groups/${GROUP_ID}/hosts/" \
    >/dev/null


echo "Adding ${RHEL9_HOST} to tomcat_lab"

api \
    -X POST \
    -d "{
          \"id\": ${RHEL9_ID}
        }" \
    "${TOWER_URL}/api/v2/groups/${GROUP_ID}/hosts/" \
    >/dev/null


echo "Launching Tower Job Template ${JOB_TEMPLATE_ID}"

response=$(api \
    -X POST \
    -d "{
          \"extra_vars\": {
            \"tomcat_jdk_choice\": \"${TOMCAT_JDK_CHOICE}\"
          }
        }" \
    "${TOWER_URL}/api/v2/job_templates/${JOB_TEMPLATE_ID}/launch/")


JOB_ID=$(echo "${response}" | jq -r '.job')


echo "Tower Job launched successfully"
echo "Job ID: ${JOB_ID}"
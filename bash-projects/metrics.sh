#!/bin/bash

Jira_test_server="https://atlassian.com/jira"
username="daniel.a.burke"
jira_test_token=""

confluence_test_server="https://atlassian.com/confluence"
confluence_test_token=""
 
bitbucket_test_server="https://atlassian.com/bitbucket"
bitbucket_test_token=""

# Fetch and count different projectTypeKey values from JIRA
declare -A projectTypes
jira_data=$(curl -G -H "Authorization: Bearer ${jira_test_token}" -s -k "${Jira_test_server}/rest/api/2/project")
keys=$(echo "$jira_data" | jq -r '.[].projectTypeKey')

# Count the occurrences of each projectTypeKey value
for key in $keys; do
    projectTypes["$key"]=$((${projectTypes["$key"]} + 1))
done

echo "Counts of different projectTypeKey values in JIRA:"
for key in "${!projectTypes[@]}"; do
    echo "$key: ${projectTypes[$key]}"
done

# Fetch and count number of spaces from Confluence
spaces_data=$(curl -s -u "${username}:${personal_access_token}" "${confluence_test_server}/rest/api/space?&limit=500")
spaces_count=$(echo "${spaces_data}" | jq '.values | length')
echo "Number of spaces in Confluence: $spaces_count"

# Fetch and count number of projects from Bitbucket
projects_data=$(curl -s -u "${username}:${personal_access_token}" "${bitbucket_test_server}/rest/api/1.0/projects?limit=1000")
projects_count=$(echo "${projects_data}" | jq '.values | length')
echo "Number of projects in Bitbucket: $projects_count"

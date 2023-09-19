#!/bin/bash

Jira_test_server_url="https://atlassian.com/jira"
username="daniel.a.burke"
test_token=""

maxResults=1000
startAt=0
hasMore=true

echo "Username,JiraID,Groups,Projects"

# Fetch all projects once
projects_json=$(curl -G -H "Authorization: Bearer ${test_token}" -s -k "${Jira_test_server_url}/rest/api/2/project")

while :; do
    # Fetch users using pagination
    users_json=$(curl -G -H "Authorization: Bearer ${test_token}" -s -k "${Jira_test_server_url}/rest/api/2/user/search?username=.&maxResults=${maxResults}&startAt=${startAt}")

    # Check if we've gotten any users back
    if [[ -z $(echo "${users_json}" | jq -r ".[]") ]]; then
        break
    fi

    # Process each user in the response
    num_users=$(echo "${users_json}" | jq '. | length')
    for ((i=0; i<$num_users; i++)); do
        name=$(echo "${users_json}" | jq -r ".[$i].name")
        key=$(echo "${users_json}" | jq -r ".[$i].key")

        # Fetch groups for the user
        groups_json=$(curl -G -H "Authorization: Bearer ${test_token}" -s -k "${Jira_test_server_url}/rest/api/2/user?username=${name}&expand=groups")
        groups=$(echo "${groups_json}" | jq -r ".groups.items[]?.name // empty" | tr '\n' ',' | sed 's/,$//')

        project_names=""
        role_ids=("10102" "10100" "10201" "10101" "10002" "10300" "10202" "10200")
        for project_key in $(echo "${projects_json}" | jq -r ".[].key"); do
            for role_id in "${role_ids[@]}"; do
                users_in_role_json=$(curl -G -H "Authorization: Bearer ${test_token}" -s -k "${Jira_test_server_url}/rest/api/2/project/${project_key}/role/${role_id}")
                if echo "$users_in_role_json" | jq -e ".actors[] | select(.name == \"$name\")" &> /dev/null; then
                    project_name=$(echo "${projects_json}" | jq -r ".[] | select(.key==\"${project_key}\") | .name")
                    project_names="$project_names,$project_name"
                    break # break out of the role_ids loop once a match is found
                fi
            done
        done

        echo "$name,$key,$groups,$project_names"
    done

    startAt=$((startAt + maxResults))
done

echo "Done"

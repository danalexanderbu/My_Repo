#!/bin/bash

bitbucket_server_url="https://****atlassian.*********/bitbucket"
username="daniel.a.burke"
personal_access_token="******"

echo "Project Key,Repository Slug,Branch,File Type,File Name,File Path,File Size"

projects_json=$(curl -s -u "${username}:${personal_access_token}" "${bitbucket_server_url}/rest/api/1.0/projects?limit=1000")
projects_keys=$(echo "${projects_json}" | jq -r '.values[].key')

file_types=("zip" "tar" "gz" "rpm" "deb" "war" "ear" 
"jar" "nupkg" "exe" "dll" "iso" "docx" "pdf" "xlsx"
"mp3" "wma" "flac" "aac" "mp4" "avi" "mkv" "mov" "flv" "ogg" "vob" "wav" "ppt"
"pptx" "xls" "doc" "rtf" "log" "7z" "rar" "bin" "bat" "so" 
"jpg" "png" "jpeg" "gif" "tiff" "svg" "psd" "mdb" "sqlite" "sln" "DS_Store" "db" "vscode")

# For each project key
for project_key in ${projects_keys}; do
    # Make a curl request to get the repositories JSON for the project
    repos_json=$(curl -s -u "${username}:${personal_access_token}" "${bitbucket_server_url}/rest/api/1.0/projects/${project_key}/repos?limit=1000")
    # Extract the repository slugs from the repositories JSON
    repos_slugs=$(echo "${repos_json}" | jq -r '.values[].slug')

    # For each repository slug
    for repo_slug in ${repos_slugs}; do
        # Make a curl request to get the default branch JSON for the repository
        default_branch_json=$(curl -s -u "${username}:${personal_access_token}" "${bitbucket_server_url}/rest/api/1.0/projects/${project_key}/repos/${repo_slug}/branches/default")
        # Extract the default branch ID from the default branch JSON
        default_branch=$(echo "${default_branch_json}" | jq -r '.displayId')

        # Prepare the next URL to get the files for the repository
        next_url="${bitbucket_server_url}/rest/api/1.0/projects/${project_key}/repos/${repo_slug}/files?at=${default_branch}"
        # While the next URL is not empty
        while [ ! -z "${next_url}" ]; do
            # Make a curl request to get the files JSON
            files_json=$(curl -s -u "${username}:${personal_access_token}" "${next_url}")
            # Set the internal field separator to newline
            IFS=$'\n'
            # Extract the file paths from the files JSON
            file_paths=$(echo "${files_json}" | jq -r '.values[]')

            for file_path in ${file_paths}; do
                # Encode the file path into URL encoding, then replace encoded slashes (%2F) back to literal slashes (/)
                encoded_file_path=$(printf '%s' "$file_path" | jq -sRr @uri | sed 's/%2F/\//g')
                # Replace spaces in the file path with URL encoded spaces (%20)
                decoded_file_path=$(echo "${file_path}" | sed 's/ /%20/g')
                # Extract the file name from the file path
                file_name="${decoded_file_path##*/}"
                # Extract the file extension from the file name
                file_extension="${file_name##*.}"
            
                # If the file extension is in the list of file types.
                # The '=~' operator in Bash means "if the left hand operand matches the extended regular expression on the right".
                # The @ symbol in Bash means "expand the array to its elements".
                if [[ " ${file_types[@]} " =~ " ${file_extension} " ]]; then
                    # Make a curl request to get the file info, including the size, using the encoded file path
                    file_info_json=$(curl -s -u "${username}:${personal_access_token}" "${bitbucket_server_url}/rest/api/1.0/projects/${project_key}/repos/${repo_slug}/browse/${encoded_file_path}?size=true&at=${default_branch}")
                    # Extract the file size from the JSON response
                    file_size=$(echo "${file_info_json}" | jq -r '.size')
                    # Replace URL encoded spaces (%20) back to literal spaces in the file name for display
                    pretty_file_name=$(echo "${file_name}" | sed 's/%20/ /g')
                    # Replace URL encoded spaces (%20) back to literal spaces in the file path for display
                    pretty_decoded_file_path=$(echo "${decoded_file_path}" | sed 's/%20/ /g')
                    # Print the project key, repository slug, default branch, file extension, file name, file path, and file size
                    echo "\"${project_key}\",\"${repo_slug}\",\"${default_branch}\",\".${file_extension}\",\"${pretty_file_name}\",\"${pretty_decoded_file_path}\",\"${file_size}\""
                fi
            done               
            # Extract the start position of the next page from the files JSON.
            # If the 'nextPageStart' field is not present in the JSON, it will return an empty string.
            next_url=$(echo "${files_json}" | jq -r '.nextPageStart // empty')
            # If the start position of the next page is not empty, it prepares the URL for the next page.
            # If the start position of the next page is empty, next_url will be set to an empty string.
            # The '+:' operator in Bash means "if variable is set and not null, then use the value of the variable, otherwise use the value after the colon".
            next_url=${next_url:+${bitbucket_server_url}/rest/api/1.0/projects/${project_key}/repos/${repo_slug}/files?start=${next_url}&at=${default_branch}}
        done
    done
done

printf "CSV completed"

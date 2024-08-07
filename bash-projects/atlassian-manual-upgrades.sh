#!/bin/bash
#separate into functions
function jira-upload () {
    user_home="/home/$(whoami)"
    server_xml_backup="$user_home/Documents/jira-server.xml"
    server_xml="/opt/atlassian/jira/conf/server.xml"
    robots="/opt/atlassian/jira/atlassian-jira/robots.txt"
    robots_backup="$user_home/Documents/jira-robots.txt"
    setenv="/opt/atlassian/jira/bin/setenv.sh"
    backup_dir="$user_home/Documents"
    downloads="$user_home/Downloads"  # Define the directory to search in

    # Ensure the backup directory exists
    mkdir -p $backup_dir

    # Make backups before starting
    cp $server_xml $server_xml_backup
    cp $robots $robots_backup
    cp $setenv $user_home/jira-setenv.sh
    cp /opt/atlassian/jira/conf/web.xml $backup_dir/jira-web.xml.bak
    cp /opt/atlassian/jira/atlassian-jira/WEB-INF/web.xml $backup_dir/jira-web-inf-web.xml.bak
    cp /opt/atlassian/jira/atlassian-jira/WEB-INF/classes/seraph-config.xml $backup_dir/jira-seraph-config.xml.bak

    # Find the files matching the pattern atlassian-jira-software-*.bin in the specified directory
    files=("$downloads"/atlassian-jira-software-*.bin)

    # Check the number of matching files
    if [ ${#files[@]} -gt 1 ]; then
        echo "Multiple matching files found:"
        select file in "${files[@]}"; do
            if [[ -n $file ]]; then
                echo "You chose: $file"
                break
            else
                echo "Invalid selection."
            fi
        done
    elif [ ${#files[@]} -eq 0 ]; then
        echo "Error: No files matching the pattern found in $downloads."
        exit 1
    else
        file=${files[0]}
        echo "Found file: $file"
    fi
    # Set execute permission
    sudo chmod +x "$file"

    # Execute the file
    sudo "$file"
    echo "Installer finished."

    # Update Jira keystore
    cd /opt/atlassian/jira/jre/lib/security
    sudo keytool -import -alias tomcat -file /etc/ssl/tomcat.crt -keystore cacerts
    echo "tomcat cert imported"

    # Update robots.txt
    cd $user_home
    cat << EOF > "$robots"
# robots.txt for JIRA
# You may specify URLs in this file that will not be crawled by search engines (Google, MSN, etc)
#
# By default, all SearchRequestViews in the IssueNavigator (e.g.: Word, XML, RSS, etc) and all IssueViews
# (XML, Printable and Word) are excluded by the /sr/ and /si/ directives below.

User-agent: *
Disallow: /
Disallow: /sr/
Disallow: /si/
Disallow: /charts
Disallow: /secure/ConfigureReport.jspa
Disallow: /secure/ConfigureReport!default.jspa
Disallow: /secure/attachmentzip/
Disallow: /secure/AboutPage.jspa
Disallow: /secure/JiraCreditsPage!default.jspa
Disallow: /secure/credits/AroundTheWorld!default.jspa
Disallow: /secure/ViewKeyboardShortcuts!default.jspa
Disallow: /secure/ViewProfile.jspa
Disallow: /login.jsp
EOF

    # Add plugin upload button
    sudo sed -i 's|JVM_SUPPORT_RECOMMENDED_ARGS=""|JVM_SUPPORT_RECOMMENDED_ARGS="-Dupm.plugin.upload.enabled=true"|' "$setenv"
    echo "added plugin upload to setenv.sh"

    # 1 hour idle timeout for /opt/atlassian/jira/conf/web.xml
    sudo sed -i '/<session-config>/,/<\/session-config>/c\
        <session-config>\
            <session-timeout>60</session-timeout>\
            <tracking-mode>COOKIE</tracking-mode>\
            <cookie-config>\
              <max-age>3600</max-age>\
            </cookie-config>\
        </session-config>' /opt/atlassian/jira/conf/web.xml
    echo "modified /opt/atlassian/jira/conf/web.xml"

    # 1 hour timeout for /opt/atlassian/jira/atlassian-jira/WEB-INF/web.xml
    sudo sed -i '/<session-config>/,/<\/session-config>/c\
        <session-config>\
            <session-timeout>60</session-timeout>\
            <tracking-mode>COOKIE</tracking-mode>\
            <cookie-config>\
              <max-age>3600</max-age>\
            </cookie-config>\
        </session-config>' /opt/atlassian/jira/atlassian-jira/WEB-INF/web.xml
    echo "modified /opt/atlassian/jira/atlassian-jira/WEB-INF/web.xml"

    # 8 hour force logout
    sudo sed -i '/<init-param>/,/<\/init-param>/ {
      /<param-name>invalidate.session.exclude.list<\/param-name>/ {
        N; N; N;
        s|</init-param>|</init-param>\
            <!-- session-timeout -->\
            <init-param>\
                <param-name>autologin.cookie.age</param-name>\
                <param-value>28800</param-value>\
            </init-param>|
    }
    }' /opt/atlassian/jira/atlassian-jira/WEB-INF/classes/seraph-config.xml
    echo "modified /opt/atlassian/jira/atlassian-jira/WEB-INF/classes/seraph-config.xml"

    # Fix directory permissions
    sudo chown jira:jira -R /opt/atlassian/jira
    echo "fixed permissions"
}

function confluence-upload () {
    user_home="/home/$(whoami)/Documents"
    server_xml_backup="$user_home/confluence-server.xml"
    server_xml="/opt/atlassian/confluence/conf/server.xml"
    robots="/opt/atlassian/confluence/confluence/robots.txt"
    robots_backup="$user_home/confluence-robots.txt"
    setenv="/opt/atlassian/confluence/bin/setenv.sh"
    backup_dir="$user_home"
    downloads="$user_home/Downloads"  # Define the directory to search in

    # Ensure the backup directory exists
    mkdir -p $backup_dir

    # Make backups before starting
    cp $server_xml $server_xml_backup
    cp $robots $robots_backup
    cp $setenv $user_home/confluence-setenv.sh
    cp /opt/atlassian/confluence/conf/web.xml $backup_dir/conf-web.xml.bak
    cp /opt/atlassian/confluence/confluence/WEB-INF/web.xml $backup_dir/con-web-inf-web.xml.bak
    cp /opt/atlassian/confluence/confluence/WEB-INF/classes/seraph-config.xml $backup_dir/con-seraph-config.xml.bak

    # Find the files matching the pattern atlassian-confluence-*.bin in the specified directory
    files=("$downloads"/atlassian-confluence-*.bin)

    # Check the number of matching files
    if [ ${#files[@]} -gt 1 ]; then
        echo "Multiple matching files found:"
        select file in "${files[@]}"; do
            if [[ -n $file ]]; then
                echo "You chose: $file"
                break
            else
                echo "Invalid selection."
            fi
        done
    elif [ ${#files[@]} -eq 0 ]; then
        echo "Error: No files matching the pattern found in $downloads."
        exit 1
    else
        file=${files[0]}
        echo "Found file: $file"
    fi
    # Set execute permission
    sudo chmod +x "$file"

    # Execute the file
    sudo "$file"
    echo "Installer finished."

    # Update confluence keystore
    cd /opt/atlassian/confluence/jre/lib/security
    sudo keytool -import -alias tomcat -file /etc/ssl/tomcat.crt -keystore cacerts
    echo "tomcat cert imported"

    # Update robots.txt
    cd $user_home
    cat << EOF > "$robots"
# robots.txt for confluence
# You may specify URLs in this file that will not be crawled by search engines (Google, MSN, etc)
#
# By default, all SearchRequestViews in the IssueNavigator (e.g.: Word, XML, RSS, etc) and all IssueViews
# (XML, Printable and Word) are excluded by the /sr/ and /si/ directives below.

User-agent: *
Disallow: /
EOF

    # Add plugin upload button
    sudo sed -i '/CATALINA_OPTS="-Datlassian.plugins.enable.wait-300 ${CATALINA_OPTS}"/a CATALINA_OPTS="-Dupm.plugin.upload.enabled=true ${CATALINA_OPTS}"' "$setenv"
    echo "added plugin upload to setenv.sh"

    # 1 hour idle timeout for /opt/atlassian/confluence/conf/web.xml
    sed -i '/<session-config>/,/<\/session-config>/c\
        <session-config>\
            <session-timeout>60</session-timeout>\
            <tracking-mode>COOKIE</tracking-mode>\
            <cookie-config>\
              <max-age>3600</max-age>\
            </cookie-config>\
        </session-config>' /opt/atlassian/confluence/conf/web.xml
    echo "modified /opt/atlassian/confluence/conf/web.xml"

    # 1 hour timeout for /opt/atlassian/confluence/confluencec/WEB-INF/web.xml
    sudo sed -i '/<session-config>/,/<\/session-config>/c\
        <session-config>\
            <session-timeout>60</session-timeout>\
            <tracking-mode>COOKIE</tracking-mode>\
            <cookie-config>\
              <max-age>3600</max-age>\
            </cookie-config>\
        </session-config>' /opt/atlassian/confluence/confluence/WEB-INF/web.xml
    echo "modified /opt/atlassian/confluence/confluence/WEB-INF/web.xml"

    # 8 hour force logout
    sudo sed -i '/<init-param>/,/<\/init-param>/ {
      /<param-name>invalidate.session.exclude.list<\/param-name>/ {
        N; N; N;
        s|</init-param>|</init-param>\
            <!-- session-timeout -->\
            <init-param>\
                <param-name>autologin.cookie.age</param-name>\
                <param-value>28800</param-value>\
            </init-param>|
    }
    }' /opt/atlassian/confluence/confluence/WEB-INF/classes/seraph-config.xml
    echo "modified /opt/atlassian/confluence/confluence/WEB-INF/classes/seraph-config.xml"

    # Fix directory permissions
    sudo chown confluence:confluence -R /opt/atlassian/confluence
    echo "fixed permissions"
}

function bitbucket-upload () {
    # need to remove oldest bitbucket version
    ls -d /opt/atlassian/bitbucket/*
    #read -p "which directory version do you want to delete: " DIR_VERSION
    #sudo rm -r /opt/atlassian/bitbucket/$DIR_VERSION

    read -p "what is the current Bitbucket version: " BITBUCKET_VERSION

    user_home="/home/$(whoami)"
    robots="/opt/atlassian/bitbucket/$BITBUCKET_VERSION/app/robots.txt"
    robots_backup="$backup_dir/bit_robots.txt"
    setenv="/opt/atlassian/bitbucket/$BITBUCKET_VERSION/bin/_start-webapp.sh"
    setenv_backup="$user_home/Documents/bit_start-webapp.sh"
    app_home="/var/atlassian/application-data/bitbucket/shared/bitbucket.properties"
    backup_dir="$user_home/Documents"
    downloads="$user_home/Downloads"

    # Ensure the backup directory exists
    mkdir -p $backup_dir
    sudo cp $app_home $user_home
    cp $setenv $setenv_backup
    cp $robots $backup_dir
    # Find the files matching the pattern atlassian-bitbucket-*.bin in the specified directory
    files=("$downloads"/atlassian-bitbucket-*.bin)

    # Check the number of matching files
    if [ ${#files[@]} -gt 1 ]; then
        echo "Multiple matching files found:"
        select file in "${files[@]}"; do
            if [[ -n $file ]]; then
                echo "You chose: $file"
                break
            else
                echo "Invalid selection."
            fi
        done
    elif [ ${#files[@]} -eq 0 ]; then
        echo "Error: No files matching the pattern found in $downloads."
        exit 1
    else
        file=${files[0]}
        echo "Found file: $file"
    fi
    # Set execute permission
    sudo chmod +x "$file"

    # Execute the file
    sudo "$file"
    echo "Installer finished."


    # Update robots.txt
    cd $backup_dir
    sudo cp $robots_backup $robots
    # Add plugin upload button
    sudo sed -i 's|JVM_SUPPORT_RECOMMENDED_ARGS=""|JVM_SUPPORT_RECOMMENDED_ARGS="-Dupm.plugin.upload.enabled=true"|' "$setenv"
    echo "added plugin upload to setenv.sh"

    # Fix directory permissions
    sudo chown bitbucket:bitbucket -R /opt/atlassian/bitbucket
    echo "fixed permissions"
}

function bamboo-upload () {
    CURRENT_BAMBOO_DIR="/opt/atlassian/bamboo"
    DOWNLOAD_DIR="/home/dburke/Downloads"
    TARGET_DIR="/opt/atlassian"
    NEW_BAMBOO_PATTERN="atlassian-bamboo-*.tar.gz"
    README_FILE="$CURRENT_BAMBOO_DIR/README.txt"

    # Function to get the current version from the README file
    get_current_version() {
        if [ -f "$README_FILE" ]; then
            grep -oP 'Bamboo\s+\K\d+\.\d+\.\d+' "$README_FILE"
        else
            echo "unknown"
        fi
    }

    # Find the new Bamboo tar.gz file
    new_bamboo_files=("$DOWNLOAD_DIR"/$NEW_BAMBOO_PATTERN)

    # Check the number of matching files
    if [ ${#new_bamboo_files[@]} -gt 1 ]; then
        echo "Error: Multiple matching files found. Please remove the extra files and try again."
        exit 1
    elif [ ${#new_bamboo_files[@]} -eq 0 ]; then
        echo "Error: No files matching the pattern found in $DOWNLOAD_DIR."
        exit 1
    else
        new_bamboo_file=${new_bamboo_files[0]}
        echo "Found file: $new_bamboo_file"

        # Get the current version
        current_version=$(get_current_version)
        if [ "$current_version" != "unknown" ]; then
            renamed_bamboo_dir="$CURRENT_BAMBOO_DIR-$current_version"
        else
            renamed_bamboo_dir="$CURRENT_BAMBOO_DIR-backup"
        fi

        # Rename the current Bamboo directory
        if [ -d "$CURRENT_BAMBOO_DIR" ]; then
            mv "$CURRENT_BAMBOO_DIR" "$renamed_bamboo_dir"
            echo "Renamed current Bamboo directory to $renamed_bamboo_dir"
        fi

        # Extract the new Bamboo tar.gz file to the target directory
        tar -xzvf "$new_bamboo_file" -C "$TARGET_DIR"

        # Rename the extracted directory to the standard Bamboo directory name
        extracted_dir=$(basename "$new_bamboo_file" .tar.gz)
        mv "$TARGET_DIR/$extracted_dir" "$CURRENT_BAMBOO_DIR"
        echo "Renamed $TARGET_DIR/$extracted_dir to $CURRENT_BAMBOO_DIR"

        # Remove the new Bamboo tar.gz file after extraction
        rm -f "$new_bamboo_file"
        echo "Removed the tar.gz file: $new_bamboo_file"
    fi
}

while true; do
    echo "Choose an option:"
    echo "1 - Jira"
    echo "2 - Confluence"
    echo "3 - Bitbucket"
    echo "4 - Bamboo"
    echo "5 - Cancel"
    read -p "Enter your choice: " choice

    case $choice in
        1) jira-upload;;
        2) confluence-upload;;
        3) bitbucket-upload;;
        4) bamboo-upload;;
        5) echo "Cancel."; break;;
        *) echo "Invalid option: $choice";;
    esac

    # Check if the user wants to exit
    if [ "$choice" = "5" ]; then
        echo "Exiting script."
        break
    fi
done

#!/bin/bash

sudo apt-get update
sudo apt-get install -y openjdk-17-jdk curl ca-certificates vim postgresql postgresql-contrib letsencrypt openssh-server

sudo systemctl enable ssh
sudo systemctl start ssh

# Install Visual Studio Code
curl -L "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" -o vscode.deb
sudo dpkg -i vscode.deb
sudo apt-get install -f -y  # Install dependencies if needed

RESPONSE_FILE1="/tmp/jira/response.varfile"
RESPONSE_FILE2="/tmp/confluence/response.varfile"
RESPONSE_FILE3="/tmp/bitbucket/response.varfile"

sudo mkdir -p /tmp/jira /tmp/confluence /tmp/bitbucket

cat <<EOF > $RESPONSE_FILE1
app.install.service$Boolean=true
app.service.port=8080
existingInstallationDir=/opt/atlassian/jira
sys.adminRights$Boolean=true
sys.confirmedUpdateInstallationString=false
sys.languageId=en
sys.installationDir=/opt/atlassian/jira
sys.proxyHost=
sys.proxy.port=
sys.confirmedUpdateInstallationString=false
executeLauncherAction$Boolean=false
EOF

cat <<EOF > $RESPONSE_FILE2
app.install.service$Boolean=true
app.service.port=8090
existingInstallationDir=/opt/atlassian/confluence
sys.adminRights$Boolean=true
sys.confirmedUpdateInstallationString=false
sys.languageId=en
sys.installationDir=/opt/atlassian/confluence
sys.proxyHost=
sys.proxy.port=
sys.confirmedUpdateInstallationString=false
executeLauncherAction$Boolean=false
EOF

cat <<EOF > $RESPONSE_FILE3
app.install.service$Boolean=true
app.service.port=7990
existingInstallationDir=/opt/atlassian/bitbucket
sys.adminRights$Boolean=true
sys.confirmedUpdateInstallationString=false
sys.languageId=en
sys.installationDir=/opt/atlassian/bitbucket
sys.proxyHost=
sys.proxy.port=
sys.confirmedUpdateInstallationString=false
executeLauncherAction$Boolean=false
EOF

declare -a urls =(
"https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-software-9.17.1-x64.bin"
"https://product-downloads.atlassian.com/software/confluence/downloads/atlassian-confluence-8.9.4-x64.bin"
"https://product-downloads.atlassian.com/software/bitbucket/downloads/atlassian-bitbucket-8.19.6-x64.bin"
)

for url in "${urls[@]}"; do
filename=$(basename $url)
curl -L $url -o $filename
sudo chmod +x $filename

if [[ $filename == *"jira"* ]]; then
    sudo ./$filename -q -varfile $RESPONSE_FILE1
elif [[ $filename == *"confluence"* ]]; then
    sudo ./$filename -q -varfile $RESPONSE_FILE2
elif [[ $filename == *"bitbucket"* ]]; then
    sudo ./$filename -q -varfile $RESPONSE_FILE3
fi
done

# Set up PostgreSQL
sudo apt-get install -f -y
sudo systemctl start postgresql
sudo systemctl enable postgresql

DB_NAME1="jiradb"
DB_USER1="jira"
DB_PASS1="jira"

DB_NAME2="confluencedb"
DB_USER2="confluence"
DB_PASS2="confluence"

DB_NAME3="bitbucketdb"
DB_USER3="bitbucket"
DB_PASS3="bitbucket"

sudo -i -u postgresql <<EOF
psql -c "CREATE DATABASE $DB_NAME1;"
psql -c "CREATE USER $DB_USER1 WITH ENCRYPTED PASSWORD '$DB_PASS1';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME1 TO $DB_USER1;"
psql -c "CREATE DATABASE $DB_NAME2;"
psql -c "CREATE USER $DB_USER2 WITH ENCRYPTED PASSWORD '$DB_PASS2';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME2 TO $DB_USER2;"
psql -c "CREATE DATABASE $DB_NAME3;"
psql -c "CREATE USER $DB_USER3 WITH ENCRYPTED PASSWORD '$DB_PASS3';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME3 TO $DB_USER3;"
EOF
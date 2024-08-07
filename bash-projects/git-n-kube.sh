#!bin/bash
### Kubernetes Installation ###
sudo mkdir -m 755 /etc/apt/keyrings
curl -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/k8s.gpg
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo swapoff -a
sudo sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab
# Docker runtime
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io
# Create required directories
sudo mkdir -p /etc/systemd/system/docker.service.d
# Create daemon json config file
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
# Start and enable Services
sudo systemctl daemon-reload 
sudo systemctl restart docker
sudo systemctl enable docker
# Configure persistent loading of modules
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
# Ensure you load modules
sudo modprobe overlay
sudo modprobe br_netfilter
# Set up required sysctl params
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
echo "Configurations added successfully!"

### Git and user Configuration ###
sudo apt update && sudo apt upgrade -y
# This script will build git from source, using openssl instead of gnutls so you can use it with HTTPS
set -eu
# Gather command line options
SKIPTESTS=
BUILDDIR=
SKIPINSTALL=
for i in "$@"; do 
  case $i in 
    -skiptests|--skip-tests) # Skip tests portion of the build
    SKIPTESTS=YES
    shift
    ;;
    -d=*|--build-dir=*) # Specify the directory to use for the build
    BUILDDIR="${i#*=}"
    shift
    ;;
    -skipinstall|--skip-install) # Skip dpkg install
    SKIPINSTALL=YES
    ;;
    *)
    #TODO Maybe define a help section?
    ;;
  esac
done

# Use the specified build directory, or create a unique temporary directory
set -x
BUILDDIR=${BUILDDIR:-$(mktemp -d)}
mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"

# Download the source tarball from GitHub
sudo apt update
git_tarball_url="$(curl --retry 5 "https://api.github.com/repos/git/git/tags" | jq -r '.[0].tarball_url')"
curl -L --retry 5 "${git_tarball_url}" --output "git-source.tar.gz"
tar -xf "git-source.tar.gz" --strip 1

# Source dependencies
# Don't use gnutls, this is the problem package.
if sudo apt remove --purge libcurl4-gnutls-dev -y; then
  # Using apt-get for these commands, they're not supported with the apt alias on 14.04 (but they may be on later systems)
  sudo apt autoremove -y
  sudo apt autoclean
fi
# Meta-things for building on the end-user's machine
sudo apt install build-essential autoconf dh-autoreconf -y
# Things for the git itself
sudo apt install libcurl4-openssl-dev tcl-dev gettext asciidoc libexpat1-dev libz-dev -y

# Build it!
make configure
# --prefix=/usr
#    Set the prefix based on this decision tree: https://i.stack.imgur.com/BlpRb.png
#    Not OS related, is software, not from package manager, has dependencies, and built from source => /usr
# --with-openssl
#    Running ripgrep on configure shows that --with-openssl is set by default. Since this could change in the
#    future we do it explicitly
./configure --prefix=/usr --with-openssl
make 
if [[ "${SKIPTESTS}" != "YES" ]]; then
  make test
fi

# Install
if [[ "${SKIPINSTALL}" != "YES" ]]; then
  # If you have an apt managed version of git, remove it
  if sudo apt remove --purge git -y; then
    sudo apt autoremove -y
    sudo apt autoclean
  fi
  # Install the version we just built
  sudo make install #install-doc install-html install-info
  echo "Make sure to refresh your shell!"
  bash -c 'echo "$(which git) ($(git --version))"'
fi
mkdir ~/.mycerts
cd ~/.mycerts
wget https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip -O unclass-certificates_pkcs7_DoD.zip
unzip unclass-certificates_pkcs7_DoD.zip
cd ~/.mycerts/certificates_pkcs7_v5_12_dod
openssl pkcs7 -print_certs -in certificates_pkcs7_v5_12_dod_pem.p7b -out dod_cert_bundle.pem
chmod 600 ~/.mycerts/certificates_pkcs7_v5_12_dod/dod_cert_bundle.pem
cd $HOME
chmod 700 ~/.mycerts
# Configure git
git config --global user.name "Daniel Burke"
git config --global user.email "daniel.burke.13@us.af.mil"
git config --global core.editor "vscode"
git config --global --unset http.sslBackend
git config --global --unset http.sslcert
git config --global --unset http.sslcrlfile
git config --global http.sslBackend openssl
git config --global http.sslCAInfo ~/.mycerts/dod_cert_bundle.pem
git config --global http.sslverify false
git config --global http.sslverify true
# Define the path to the Documents directory
DOCUMENTS_DIR="$HOME/Documents"
# Go to the Documents directory
cd "$DOCUMENTS_DIR" || { echo "Failed to switch to the Documents directory"; exit 1; }
# Check if SSH Key already exists
if [ ! -f ~/.ssh/github_ssh_key ]; then
    # 1. Generate SSH Key (without passphrase for automation; you can modify as needed)
    ssh-keygen -t ed25519 -C "danalexanderbu@gmail.com" -f ~/.ssh/github_ssh_key || { echo "SSH key generation failed"; exit 1; }
    # 2. Start the ssh-agent in the background
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/github_ssh_key || { echo "Failed to add SSH key to agent"; exit 1; }
    
    # 3. Prompt user to manually add the public key to GitHub
    echo "Please add the following SSH key to your GitHub account:"
    cat ~/.ssh/github_ssh_key.pub
    echo "Once you've added it, press any key to continue..."
    read -n 1 -s
else
    echo "SSH key already exists. Skipping generation..."
fi
# Inform user to continue with cloning
echo "You can now clone your repositories."
# Clone the repositories into their respective folders
git clone git@github.com:danalexanderbu/personal.git personal || { echo "Failed to clone personal"; exit 1; }
git clone git@github.com:danalexanderbu/My_Repo.git My_Repo || { echo "Failed to clone My_Repo"; exit 1; }
cd $HOME
echo "Repositories have been cloned!"

### Install Obsidian ###
latest_release_url_Obsidian=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
wget "$latest_release_url_Obsidian" 
file_name=$(basename "$latest_release_url_Obsidian")
sudo dpkg -i "$file_name"
rm "$file_name"
mkdir -p ~/.local/share/applications/
chmod -R 755 ~/.local/share/applications/
tee ~/.local/share/applications/Obsidian.desktop <<EOF
[Desktop Entry]
Type=Application
Name=ObsidianVault
Comment=Open Obsidian with a specific vault
Exec=obsidian --vault ~/Documents/personal/Notes
Terminal=false
Categories=Office;Utility;
EOF
sudo apt --fix-broken install -y

### Configure Windows 11 ###
# Opens setup with default markdown viewer
# uncomment the line below to open the markdown file if you are not restarting
#xdg-open ~/Documents/personal/Notes/Installing\ Windows\ via\ command\ line.md

### Configure KDE###
CONFIG_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

# Backup the configuration file
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# List of apps to add to favorites
declare -a apps=("applications:firefox.desktop" "applications:brave-browser.desktop" "applications:google-chrome.desktop" "applications:code.desktop" "applications:org.kde.kate.desktop" "applications:org.kde.konsole.desktop" "applications:org.kde.dolphin.desktop" "applications:thunderbird.desktop" "applications:obsidian.desktop")

# Extract the current launchers line from the specific section
current_launchers=$(grep -A1 "\[Containments\]\[2\]\[Applets\]\[5\]\[Configuration\]\[General\]" "$CONFIG_FILE" | grep "launchers=")

# Strip the 'launchers=' part to just get the comma-separated list
current_launchers=${current_launchers#launchers=}

# Add apps to the launchers line if they're not already present
for app in "${apps[@]}"; do
    if [[ ! $current_launchers =~ $app ]]; then
        current_launchers="$current_launchers,$app"
    fi
done

# Update the configuration file with the modified launchers for the specific section
sed -i "/\[Containments\]\[2\]\[Applets\]\[5\]\[Configuration\]\[General\]/,+1s|^launchers=.*$|launchers=$current_launchers|" "$CONFIG_FILE"
echo "Finished setting up your system!"
sudo reboot
#!/bin/bash
###Debian 12 approved###
### Apt Installs ###
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
sudo update-initramfs -u
sudo apt-add-repository non-free
sudo apt install software-properties-common -y
sudo apt-add-repository contrib non-free -y
sudo apt update -y
install=(
    libpcsclite1
    pcscd
    libccid
    libpcsc-perl
    pcsc-tools
    libnss3-tools
    ffmpeg
    obs-studio
    openssl
    qbittorrent
    ttf-mscorefonts-installer
    python3
    python3-pip
    vim
    ethtool
    net-tools
    nmap
    samba
    gnome-keyring
    apt-transport-https
    docker
    gnupg2
    ebtables
    aria2
    thunderbird
    ufw
    nala
    kitty
    timeshift
    nvidia-driver
    nfs-common
    neofetch
    curl
    lsb-release
    unattended-upgrades
)
for p in "${install[@]}"; do
    if ! dpkg-query -Wf'${db:Status-abbrev}' "$p" 2>/dev/null | grep -q '^i'; then
        sudo apt install "$p" -y || { echo "Failed to install $p"; exit 1; }
    fi
done
sudo fc-cache -f -v
sudo apt install $(check-language-support) -y
sudo apt update -y && sudo apt upgrade -y
sudo apt remove --purge kwalletmanager

### Download and Install DEB Packages ###
declare -a urls=(
"https://dl.discordapp.net/apps/linux/0.0.25/discord-0.0.25.deb"
"https://az764295.vo.msecnd.net/stable/704ed70d4fd1c6bd6342c436f1ede30d1cff4710/code_1.77.3-1681292746_amd64.deb"
"https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
"https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb"
"https://updates.torguard.biz/Software/Linux/torguard-latest-amd64.deb"
"https://cdn.zoom.us/prod/5.15.12.7665/zoom_amd64.deb"
"http://ftp.us.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_20230311_all.deb"
"http://repo.steampowered.com/steam/archive/precise/steam_latest.deb"
)

for url in "${urls[@]}"; do
    file_name=$(basename "$url")
    # Download the .deb package
    wget "$url" -O "$file_name"
    echo "Successfully downloaded $file_name"

    # Install the .deb package
    sudo dpkg -i "$file_name" || sudo apt --fix-broken install -y
    echo "Successfully installed $file_name"
    
    # Remove the downloaded .deb package
    rm "$file_name"
done

steam &
cd $HOME

### Kitty Terminal ###
# Open the kitty terminal and wait 5 seconds for it to create the config directory
kitty & 
sleep 5
# Create the kitty config dotfiles directory
if [ ! -d "$HOME/.config/kitty" ]; then
    mkdir -p "$HOME/.config/kitty"
fi
cd $HOME/.config/kitty
wget https://github.com/ryanoasis/nerd-fonts.git -O nerd-fonts.zip
unzip nerd-fonts.zip
sudo mv nerd-fonts /usr/share/fonts
fc-cache -fv
tee ~/.config/kitty/kitty.conf <<EOF
# Layan theme inspired kitty configuration

shell bash -c "neofetch; exec bash"

# Font and size
font_family      Fira Code Regular Nerd Font Complete Mono
font_size        12.0

# Window padding
window_padding_width 10
window_padding_height 10

# Colors
foreground       #00FF00
background       #2E3440
background_opacity 0.8

# Normal colors
color0           #3B4252
color1           #BF616A
color2           #A3BE8C
color3           #EBCB8B
color4           #81A1C1
color5           #B48EAD
color6           #88C0D0
color7           #E5E9F0

# Bright colors
color8           #4C566A
color9           #BF616A
color10          #A3BE8C
color11          #EBCB8B
color12          #81A1C1
color13          #B48EAD
color14          #8FBCBB
color15          #ECEFF4

# Cursor
shell_integration no-cursor
cursor_shape 	block
cursor           #D8DEE9
cursor_text_color #2E3440
cursor_blink_internal 5

# Selection
selection_foreground #2E3440
selection_background #88C0D0

# Borders
active_border_color   #5E81AC
inactive_border_color #4C566A
enable_tab_bar yes
tab_bar_border_width 0
tab_bar_border_color #4C566A
tab_bar_background_color #2E3440
tab_bar_foreground_color #ECEFF4
tab_bar_font_size 12.0
tab_bar_font_family Fira Code
tab_bar_padding 10.0
tab_bar_margin_top 10.0
tab_bar_margin_bottom 10.0
tab_bar_margin_left 10.0
tab_bar_margin_right 10.0

# Scrolling
scrollback_lines 2000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS

# Mouse
mouse_hide_wait 0.5
strip_trailing_spaces never
EOF
# Set kitty as the default terminal
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/kitty 50
sudo update-alternatives --config x-terminal-emulator

cd $HOME

### Btop ###
latest_release_btop=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest | jq -r .assets[11].browser_download_url)
btop_file_name=$(basename "$latest_release_btop")
wget "$latest_release_btop" -O "$btop_file_name"
tar -xjf "$btop_file_name"
cd btop
./install.sh
cd $HOME
rm -r "$btop_file_name"

### Firefox Brower ###
sudo apt remove firefox-esr -y
sudo apt purge firefox-esr -y
sudo gpg --keyserver keyserver.ubuntu.com --recv-keys 2667CA5C
sudo gpg -ao ~/ubuntuzilla.gpg --export 2667CA5C
cat ubuntuzilla.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/ubuntuzilla.gpg
sudo rm ~/ubuntuzilla.gpg
echo "deb [signed-by=/etc/apt/keyrings/ubuntuzilla.gpg] http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main" | sudo tee /etc/apt/sources.list.d/ubuntuzilla.list > /dev/null
sudo apt update -y
sudo apt install firefox-mozilla-build -y

### CAC ###
wget https://raw.githubusercontent.com/danalexanderbu/My_Repo/master/bash-projects/deb_cac_setup.sh && chmod +x deb_cac_setup.sh && sudo ./deb_cac_setup.sh

### Kubernetes ###


### Brave Browser ###
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update -y && sudo apt install brave-browser -y

### Git ###
#make git from source
wget https://raw.githubusercontent.com/danalexanderbu/My_Repo/master/bash-projects/git-openssl.sh && chmod +x git-openssl.sh && ./git-openssl.sh
rm git-openssl.sh
cd $HOME
mkdir ~/.mycerts
cd ~/.mycerts
wget https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip -O unclass-certificates_pkcs7_DoD.zip
unzip unclass-certificates_pkcs7_DoD.zip
cd ~/.mycerts/certificates_pkcs7_v5_12_dod
openssl pkcs7 -print_certs -in certificates_pkcs7_v5_12_dod_pem.p7b -out dod_cert_bundle.pem
chmod 600 ~/.mycerts/certificates_pkcs7_v5_12_dod/dod_cert_bundle.pem
cd $HOME
chmod 700 ~/.mycerts
# Prompt the user for their name and email
read -p "Please enter your name: " name
read -p "Please enter your email: " email
git config --global user.name "$name"
git config --global user.email "$email"
git config --global core.editor "vscode"
#git config --global --unset http.sslBackend
#git config --global --unset http.sslcert
#git config --global --unset http.sslcrlfile
#git config --global http.sslBackend openssl
#git config --global http.sslCAInfo ~/.mycerts/dod_cert_bundle.pem
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
    # 3. Prompt user to manually add the public key to GitHub
    echo "Please add the following SSH key to your GitHub account:"
    cat ~/.ssh/github_ssh_key.pub
    echo "Once you've added it, press any key to continue..."
    read -n 1 -s
else
    echo "SSH key already exists. Skipping generation..."
fi
# 2. Start the ssh-agent in the background and add the SSH key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_ssh_key || { echo "Failed to add SSH key to agent"; exit 1; }
# Update or create SSH config to use the specific key for GitHub
if [ ! -f ~/.ssh/config ]; then
    touch ~/.ssh/config
fi
echo -e "Host github.com\n  IdentityFile ~/.ssh/github_ssh_key" >> ~/.ssh/config
# Inform user to continue with cloning
echo "You can now clone your repositories."
# Clone the repositories into their respective folders
git clone git@github.com:danalexanderbu/personal.git personal || { echo "Failed to clone personal"; exit 1; }
git clone git@github.com:danalexanderbu/My_Repo.git My_Repo || { echo "Failed to clone My_Repo"; exit 1; }
cd $HOME

### Flatpak ###
sudo apt install flatpak
sudo apt install plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

### Battle.net Installation ###
# Add a non steam game to steam called Battle.net and install it
wget "https://www.battle.net/download/getInstallerForGame?os=win&locale=enUS&gameProgram=BATTLENET_APP" -O "Battle.net-Setup.exe"

### Proton GE Custom Installation ###
latest_release_url_GE=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | jq -r .assets[1].browser_download_url)
file_name=$(basename "$latest_release_url_GE")
wget "$latest_release_url_GE" -O "$file_name"
folder_name=$(basename "$file_name" .tar.gz)
# Check if the latest GE folder is already there
if [ -d "$HOME/.steam/steam/compatibilitytools.d/$folder_name" ]; then
    echo "Latest Proton GE version ($folder_name) is already installed. Removing the downloaded file."
    rm "$file_name"
else
    tar -xzvf "$file_name"
    
    # Create directory if it doesn't exist
    if [ ! -d "$HOME/.steam/steam/compatibilitytools.d" ]; then
        mkdir "$HOME/.steam/steam/compatibilitytools.d"
    fi
    
    mv "$folder_name" "$HOME/.steam/steam/compatibilitytools.d/"
    rm "$file_name"
fi

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

### VirtualBox Installation ###
# Add the Oracle VBox 2016 public key
curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/vbox.gpg
# Add the Oracle VBox public key
curl -fsSL https://www.virtualbox.org/download/oracle_vbox.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/oracle_vbox.gpg
# Add the VirtualBox repository to the system's APT source list
# "$(lsb_release -cs)" dynamically gets the codename of your Debian distribution.
echo "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
# Update the local package index to include the new VirtualBox repository
sudo apt update
# Install the Linux headers and dkms for the current running kernel
sudo apt install linux-headers-$(uname -r) dkms -y
# Install VirtualBox version 7.0
sudo apt install virtualbox-7.0 -y
# Add the current user to the vboxusers group to grant permission to access the vboxdrv kernel module
sudo usermod -aG vboxusers $USER
# Change the user’s group to vboxusers for the current session
newgrp vboxusers
# Download the Oracle VM VirtualBox Extension Pack
wget https://download.virtualbox.org/virtualbox/7.0.10/Oracle_VM_VirtualBox_Extension_Pack-7.0.10.vbox-extpack
# Install the Oracle VM VirtualBox Extension Pack
sudo vboxmanage extpack install Oracle_VM_VirtualBox_Extension_Pack-7.0.10.vbox-extpack
# VM Configuration Variables
VM_NAME="Windows11_VM"
#ISO_PATH="Windows11.iso"
VM_HDD_PATH="$VM_NAME.vdi"
VM_HDD_SIZE="75000"  # 75GB
VM_RAM="4096"        # 4GB
VM_VRAM="128"        # 128MB
#Download Windows 11 ISO from google drive so it can be used consistently
FILE_ID="1WzDO6lPa4zb9mqxNewz6pahopoLTbczz"
CONFIRM=$(curl -sc /tmp/gcookie "https://drive.google.com/uc?export=download&id=${FILE_ID}" | grep -o 'confirm=[^&]*' | sed 's/confirm=//')
curl -Lb /tmp/gcookie "https://drive.google.com/uc?export=download&confirm=${CONFIRM}&id=${FILE_ID}" -o Windows11.iso
# Check if curl was successful and the file has a reasonable size (here, I'm assuming at least 1GB(1B bytes) for the ISO)
if [ $? -ne 0 ] || [ $(stat -c %s "$ISO_PATH") -lt 1000000000 ]; then
    echo "Error: Windows 11 ISO download failed or file is incomplete. Exiting."
    exit 1
fi
# Create the VM in VirtualBox
VBoxManage createvm --name $VM_NAME --ostype "Windows10_64" --register
# Set VM resources
VBoxManage modifyvm $VM_NAME --memory $VM_RAM --vram $VM_VRAM
# Create virtual hard drive for the VM
VBoxManage createhd --filename $VM_HDD_PATH --size $VM_HDD_SIZE
# Attach HDD to the VM
VBoxManage storagectl $VM_NAME --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $VM_HDD_PATH
# Attach ISO (Windows 11 installation media) to the VM
VBoxManage storagectl $VM_NAME --name "IDE Controller" --add ide
VBoxManage storageattach $VM_NAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $ISO_PATH
# Set up Bridged Networking for VM
#VBoxManage modifyvm $VM_NAME --nic1 bridged --bridgeadapter1 "$(VBoxManage list bridgedifs | head -n 1 | cut -d ':' -f 2 | xargs)"
 Start the VM (Optional - Uncomment if you want to automatically start the VM after creation)
#VBoxManage startvm $VM_NAME
echo "VM created and ISO attached. You can now start the VM from VirtualBox."

### Python Packages ###
packages=(
aiohttp
aiosignal
alpha-vantage
api
async-generator
async-timeout
attrs
beautifulsoup4
certifi
charset-normalizer
et
et-xmlfile
exceptiongroup
frozenlist
greenlet
h11
idna
multidict
nose
numpy
openpyxl
outcome
packaging
pandas
patsy
Pint
psycopg
psycopg2-binary
PySocks
python-dateutil
pytz
regex
requests
scipy
selenium
sniffio
sortedcontainers
soupsieve
SQLAlchemy
statsmodels
tk
tqdm
trio
trio-websocket
typing_extensions
tzdata
urllib3
var
workbook
wsproto
xlrd
xlutils
xlwt
yarl
)
#more effecient way to install python packages than for loop
pip3 install ${packages[@]} --break-system-packages

### Configure UFW ###
sudo ufw enable
#Allow internet
sudo ufw allow 80
sudo ufw allow 443
#Allow Git
sudo ufw allow 22
sudo ufw allow 9418
#Allow unraid
sudo ufw allow from 192.168.1.133 to any port 80
sudo ufw allow from 192.168.1.133 to any port 443
sudo ufw allow from 192.168.1.133 to any port 137:139
sudo ufw allow from 192.168.1.133 to any port 445
#Allow steam
sudo ufw allow 27000:27050/udp
sudo ufw allow 27000:27050/tcp
sudo ufw allow 27015:27030/udp
sudo ufw allow 27036:27037/tcp
sudo ufw allow 27031:27036/udp
sudo ufw allow 4380/udp
sudo ufw restart

### Configure .bashrc ###
# Backup the existing .bashrc
cp ~/.bashrc ~/.bashrc_backup
# Append the new content to .bashrc using tee
### My custom .bashrc file ###
cat << 'EOF' | tee -a ~/.bashrc > /dev/null
# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Color for manpages in less makes manpages a little easier to read
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

#My custom aliases
alias uu="sudo nala update && sudo nala upgrade"

# Alias's for multiple directory listing commands
alias la='ls -Alh' # show hidden files
alias ls='ls -aFh --color=always' # add colors and file type extensions
alias lx='ls -lXBh' # sort by extension
alias lk='ls -lSrh' # sort by size
alias lc='ls -lcrh' # sort by change time
alias lu='ls -lurh' # sort by access time
alias lr='ls -lRh' # recursive ls
alias lt='ls -ltrh' # sort by date
alias lm='ls -alh |more' # pipe through 'more'
alias lw='ls -xAh' # wide listing format
alias ll='ls -Fls' # long listing format
alias labc='ls -lap' #alphabetical sort
alias lf="ls -l | egrep -v '^d'" # files only
alias ldir="ls -l | egrep '^d'" # directories only

# Change directory aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Search command line history
alias h="history | grep "

# Search files in the current folder
alias f="find . | grep "

# Count all files (recursively) in the current folder
alias countfiles="for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null"

# Show open ports
alias openports='netstat -nape --inet'

# Alias's for archives
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# Show all logs in /var/log
alias logs="sudo find /var/log -type f -exec file {} \; | grep 'text' | cut -d' ' -f1 | sed -e's/:$//g' | grep -v '[0-9]$' | xargs tail -f"

# Extracts any archive(s) (if unp isn't installed)
extract () {
	for archive in "$@"; do
		if [ -f "$archive" ] ; then
			case $archive in
				*.tar.bz2)   tar xvjf $archive    ;;
				*.tar.gz)    tar xvzf $archive    ;;
				*.bz2)       bunzip2 $archive     ;;
				*.rar)       rar x $archive       ;;
				*.gz)        gunzip $archive      ;;
				*.tar)       tar xvf $archive     ;;
				*.tbz2)      tar xvjf $archive    ;;
				*.tgz)       tar xvzf $archive    ;;
				*.zip)       unzip $archive       ;;
				*.Z)         uncompress $archive  ;;
				*.7z)        7z x $archive        ;;
				*)           echo "don't know how to extract '$archive'..." ;;
			esac
		else
			echo "'$archive' is not a valid file!"
		fi
	done
}

# Show current network information
netinfo ()
{
	echo "--------------- Network Information ---------------"
	/sbin/ifconfig | awk '/inet / {print "IP Address: " $2}'
	echo ""
	/sbin/ifconfig | awk '/broadcast / {print "Broadcast Address: " $4}'
	echo ""
	/sbin/ifconfig | awk '/ether / {print "MAC Address: " $2}'
	echo "---------------------------------------------------"
}

# IP address lookup
alias whatismyip="whatsmyip"
function whatsmyip ()
{
	# Dumps a list of all IP addresses for every device
	# /sbin/ifconfig |grep -B1 "inet addr" |awk '{ if ( $1 == "inet" ) { print $2 } else if ( $2 == "Link" ) { printf "%s:" ,$1 } }' |awk -F: '{ print $1 ": " $3 }';
	
	### Old commands
	# Internal IP Lookup
	#echo -n "Internal IP: " ; /sbin/ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'
#
#	# External IP Lookup
	#echo -n "External IP: " ; wget http://smart-ip.net/myip -O - -q
	
	# Internal IP Lookup.
	if [ -e /sbin/ip ];
	then
		echo -n "Internal IP: " ; /sbin/ip addr show enp6s0 | grep "inet " | awk -F: '{print $1}' | awk '{print $2}'
	else
		echo -n "Internal IP: " ; /sbin/ifconfig enp6s0 | grep "inet " | awk -F: '{print $1} |' | awk '{print $2}'
	fi

	# External IP Lookup 
	echo -n "External IP: " ; curl -s ifconfig.me
}

# Show the current distribution
distribution() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  else
    echo "unknown"
  fi
}

# Show the current version of the operating system
ver() {
  local dtype
  dtype=$(distribution)

  if [ "$dtype" == "rhel" ] || [ "$dtype" == "centos" ]; then
    cat /etc/redhat-release && uname -a
  elif [ "$dtype" == "suse" ] || [ "$dtype" == "opensuse" ]; then
    cat /etc/os-release # SuSE and openSUSE use os-release
  elif [ "$dtype" == "debian" ] || [ "$dtype" == "ubuntu" ]; then
    lsb_release -a
  elif [ "$dtype" == "gentoo" ]; then
    cat /etc/gentoo-release
  elif [ "$dtype" == "mandriva" ]; then
    cat /etc/mandriva-release
  elif [ "$dtype" == "slackware" ]; then
    cat /etc/slackware-version
  else
    if [ -s /etc/issue ]; then
      cat /etc/issue
    else
      echo "Error: Unknown distribution"
      exit 1
    fi
  fi
}

# Move and go to the directory
mvg ()
{
	if [ -d "$2" ];then
		mv "$1" "$2" && cd "$2"
	else
		mv "$1" "$2"
	fi
}

# Copy file with a progress bar
cpp()
{
	set -e
	strace -q -ewrite cp -- "${1}" "${2}" 2>&1 \
	| awk '{
	count += $NF
	if (count % 10 == 0) {
		percent = count / total_size * 100
		printf "%3d%% [", percent
		for (i=0;i<=percent;i++)
			printf "="
			printf ">"
			for (i=percent;i<100;i++)
				printf " "
				printf "]\r"
			}
		}
	END { print "" }' total_size="$(stat -c '%s' "${1}")" count=0
}
EOF
source ~/.bashrc

### Configure fstab ###
# Create the mount points
sudo mkdir /mnt/Movies
sudo mkdir /mnt/TV
sudo mkdir /mnt/Disney\ Movies
# Add the mount points to fstab
echo "192.168.1.133:/mnt/user/Movies /mnt/Movies nfs defaults 0 0" | sudo tee -a /etc/fstab
echo "192.168.1.133:/mnt/user/TV /mnt/TV nfs defaults 0 0" | sudo tee -a /etc/fstab
echo "192.168.1.133:/mnt/user/Disney\040Movies /mnt/Disney\040Movies nfs defaults 0 0" | sudo tee -a /etc/fstab

### Automate Security Updates ###
#echo 'Unattended-Upgrade::Allowed-Origins {' | sudo tee /etc/apt/apt.conf.d/50unattended-upgrades
#echo '        "${distro_id}:${distro_codename}-security";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
#echo '//      "${distro_id}:${distro_codename}-updates";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
#echo '};' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
#echo 'APT::Periodic::Update-Package-Lists "1";' | sudo tee /etc/apt/apt.conf.d/20auto-upgrades
#echo 'APT::Periodic::Download-Upgradeable-Packages "1";' | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades
#echo 'APT::Periodic::AutocleanInterval "7";' | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades
#echo 'APT::Periodic::Unattended-Upgrade "1";' | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades


### Configure Theme ###
cd $HOME/Documents/
# Clone the Layan-kde repository from GitHub to the current directory (Documents)
git clone https://github.com/vinceliuice/Layan-kde.git
cd Layan-kde
./install.sh
cd $HOME/Documents/
# Clone the Tela-icon-theme repository from GitHub to the current directory (Documents) 
git clone https://github.com/vinceliuice/Tela-icon-theme.git
cd Tela-icon-theme
# Install the Tela icon theme 
./install.sh
cd $HOME

echo "All tasks completed successfully."
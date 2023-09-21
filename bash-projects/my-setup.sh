#!/bin/bash

### Update the system and install required tools ###
sudo add-apt-repository ppa:bashtop-monitor/bashtop
sudo add-apt-repository ppa:obsproject/obs-studio
#deb http://deb.debian.org/debian/ bookworm main contrib non-free
#dpkg --add-architecture i386
sudo apt update && sudo apt upgrade -y
installs=(
  steam
  #steam-installer
  #mesa-vulkan-drivers
  #libglx-mesa0:i386
  #mesa-vulkan-drivers:i386
  #libgl1-mesa-dri:i386
  #libgtk2.0-0:i386
  #dnsmasq
  #resolvconf
  vim
  jq
  xclip
  bashtop
  wget
  curl
  python3
  ca-certificates
  postgresql
  net-tools
  nmap
  network-manager
  apt-transport-https
  openssl
  samba
  ttf-mscorefonts-installer
  docker.io
  gnupg2
  software-properties-common
  ebtables
  ethtool
  qbittorrent
  virtualbox
  aria2
  libkf5config-bin
  openssl
  ufw
  kate
  ffmpeg
  obs-studio
)
for package in "${installs[@]}"; do
    if ! dpkg-query -Wf'${db:Status-abbrev}' "$package" 2>/dev/null | grep -q '^i'; then
        sudo apt install "$package" -y || { echo "Failed to install $package"; exit 1; }
    fi
done

### Start steam and login ###
steam &
# service dnsmasq restart
# service resolvconf restart
#Steam-installer will install Steam to ~/.steam/debian-installation to run Steam, you will need to run the shell script located in this directory.
#~/.steam/debian-installation/steam.sh
#fix errors from steam runtime
#find ~/.steam/root/ \( -name "libgcc_s.so*" -o -name "libstdc++.so*" -o -name "libxcb.so*" \) -print -delete
#By default, it will also use newer versions of certain libraries from the host system if available. You can disable this functionality, and force utilization of the older Steam runtime, by running Steam with:
#STEAM_RUNTIME_PREFER_HOST_LIBRARIES=0 steam
#Run these commands to remove runtime libraries known to cause issues with Debian:
# rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/usr/lib/i386-linux-gnu/libstdc++.so.6
# rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/lib/i386-linux-gnu/libgcc_s.so.1
# rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/amd64/lib/x86_64-linux-gnu/libgcc_s.so.1
# rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/amd64/usr/lib/x86_64-linux-gnu/libstdc++.so.6
# rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/usr/lib/i386-linux-gnu/libxcb.so.1
# rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/lib/i386-linux-gnu/libgpg-error.so.0m
#It's also necessary to link two libraries because the libudev.so.0 file is currently not available in Debian:
#ln -s /lib/i386-linux-gnu/libudev.so.1 /lib/i386-linux-gnu/libudev.so.0
#LD_LIBRARY_PATH=~/.steam/bin32 ldd ~/.steam/bin32/steamclient.so | grep 'not found'
#no sound in games
# rm -rf ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/usr/lib/i386-linux-gnu/alsa-lib
# rm -rf ~/.steam/debian-installation/ubuntu12_32/steam-runtime/amd64/usr/lib/x86_64-linux-gnu/alsa-lib
# rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/usr/lib/i386-linux-gnu/libasound.so.*
# rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/amd64/usr/lib/x86_64-linux-gnu/libasound.so.*
cd $HOME

### Download and Install DEB Packages ###
declare -a urls=(
"https://dl.discordapp.net/apps/linux/0.0.25/discord-0.0.25.deb"
"https://az764295.vo.msecnd.net/stable/704ed70d4fd1c6bd6342c436f1ede30d1cff4710/code_1.77.3-1681292746_amd64.deb"
"https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
"https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb"
"https://torguard.net/downloads/new/torguard-latest-amd64.deb"
"https://cdn.zoom.us/prod/5.15.12.7665/zoom_amd64.deb"
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

### Battle.net Installation ###
# Add a non steam game to steam called Battle.net and install it
wget "https://www.battle.net/download/getInstallerForGame?os=win&locale=enUS&gameProgram=BATTLENET_APP" -O "Battle.net-Setup.exe"

### Firefox Installation and Configuration ###
sudo apt --fix-broken install -y
sudo snap remove --purge firefox
sudo apt purge firefox -y
if ! grep -q "^deb .*mozillateam/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  sudo add-apt-repository ppa:mozillateam/ppa -y
fi
sudo tee /etc/apt/preferences.d/Mozilla <<EOF
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
sudo apt update
sudo apt install firefox -y
sudo echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:'$(lsb_release -cs)'";' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox

### GitHub Script for CAC Execution ###
curl -LO "https://github.com/danalexanderbu/My_Repo/raw/536b4fa768aed767abed235ee9f514cb0b747895/bash-projects/cac_setup.sh"
chmod +x cac_setup.sh
./cac_setup.sh

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

### Microsoft Fonts and Language Support ###
sudo add-apt-repository multiverse -y
sudo apt update
sudo apt upgrade -y
sudo fc-cache -f -v
sudo apt install $(check-language-support) -y

### Other Essential Software Installations ###
sudo apt install gnome-keyring -y
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update
sudo apt install brave-browser -y
sudo apt --fix-broken install -y
 
### Flatpak and Bottles Installation ###
sudo apt install flatpak gnome-software-plugin-flatpak -y
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.usebottles.bottles -y

### VirtualBox Installation ###
# VM Configuration Variables
#VM_NAME="Windows11_VM"
#ISO_PATH="Windows11.iso"
#VM_HDD_PATH="$VM_NAME.vdi"
#VM_HDD_SIZE="75000"  # 75GB
#VM_RAM="4096"        # 4GB
#VM_VRAM="128"        # 128MB
#Download Windows 11 ISO from google drive so it can be used consistently
#FILE_ID="1WzDO6lPa4zb9mqxNewz6pahopoLTbczz"
#CONFIRM=$(curl -sc /tmp/gcookie "https://drive.google.com/uc?export=download&id=${FILE_ID}" | grep -o 'confirm=[^&]*' | sed 's/confirm=//')
#curl -Lb /tmp/gcookie "https://drive.google.com/uc?export=download&confirm=${CONFIRM}&id=${FILE_ID}" -o Windows11.iso
# Check if curl was successful and the file has a reasonable size (here, I'm assuming at least 1GB(1B bytes) for the ISO)
#if [ $? -ne 0 ] || [ $(stat -c %s "$ISO_PATH") -lt 1000000000 ]; then
#    echo "Error: Windows 11 ISO download failed or file is incomplete. Exiting."
#    exit 1
#fi
# Create the VM in VirtualBox
#VBoxManage createvm --name $VM_NAME --ostype "Windows10_64" --register
# Set VM resources
#VBoxManage modifyvm $VM_NAME --memory $VM_RAM --vram $VM_VRAM
# Create virtual hard drive for the VM
#VBoxManage createhd --filename $VM_HDD_PATH --size $VM_HDD_SIZE
# Attach HDD to the VM
#VBoxManage storagectl $VM_NAME --name "SATA Controller" --add sata --controller IntelAhci
#VBoxManage storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $VM_HDD_PATH
# Attach ISO (Windows 11 installation media) to the VM
#VBoxManage storagectl $VM_NAME --name "IDE Controller" --add ide
#VBoxManage storageattach $VM_NAME --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $ISO_PATH
# Set up Bridged Networking for VM
#VBoxManage modifyvm $VM_NAME --nic1 bridged --bridgeadapter1 "$(VBoxManage list bridgedifs | head -n 1 | cut -d ':' -f 2 | xargs)"
# Start the VM (Optional - Uncomment if you want to automatically start the VM after creation)
#VBoxManage startvm $VM_NAME
#echo "VM created and ISO attached. You can now start the VM from VirtualBox."

### Install python packages ###\
#Pip3 expects each package to be space-separated, not comma-separated.
sudo apt install python3-pip -y
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
pip3 install ${packages[@]}

sudo ufw enable

### Configure Dropbox ###
# Download the latest version of Dropbox and save it as dropbox.tar.gz
wget -O "$HOME/dropbox.tar.gz" "https://www.dropbox.com/download?plat=lnx.x86_64"
# Extract the contents of the archive to ~/.dropbox-dist
tar -xvzf "$HOME/dropbox.tar.gz" -C "$HOME"
# Start the daemon
# Note: This will create a symbolic link to the daemon in ~/.dropbox-dist
# Make the daemon executable
if [ ! -x "$HOME/.dropbox-dist/dropboxd" ]; then
    chmod +x "$HOME/.dropbox-dist/dropboxd"
else
    echo "Dropbox daemon already executable. Skipping..."
fi
# Check if Dropbox is running before killing it
if pgrep dropbox > /dev/null; then
    pkill dropbox
fi
cd $HOME

### Configure .bashrc ###
# Backup the existing .bashrc
cp ~/.bashrc ~/.bashrc_backup
# Append the new content to .bashrc using tee
cat << 'EOF' | tee -a ~/.bashrc > /dev/null
### My custom .bashrc file ###
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

export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64

#My custom aliases
alias uu="sudo apt update && sudo apt upgrade"

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

echo "All tasks completed successfully. Starting Kubernetes and Git installation..."
wget https://raw.githubusercontent.com/danalexanderbu/My_Repo/master/bash-projects/git-n-kube.sh && chmod +x git-n-kube.sh && ./git-n-kube.sh

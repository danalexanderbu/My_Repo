#!/bin/bash

### Update the system and install required tools ###
if grep -iq "Ubuntu" /etc/os-release; then
    sudo add-apt-repository ppa:obsproject/obs-studio -y
fi

# Add Debian specific repositories
echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware\ndeb http://deb.debian.org/debian/ bookworm main contrib non-free\ndeb http://deb.debian.org/debian bullseye-backports main contrib non-free\ndeb-src http://deb.debian.org/debian bullseye-backports main contrib non-free\ndeb https://fasttrack.debian.net/debian-fasttrack/ bullseye-fasttrack main contrib\ndeb https://fasttrack.debian.net/debian-fasttrack/ bullseye-backports-staging main contrib\n" | sudo tee /etc/apt/sources.list.d/custom-repos.list
sudo dpkg --add-architecture i386
sudo apt install fasttrack-archive-keyring
installs=(
  dnsmasq
  resolvconf
  nvidia-driver
  firmware-misc-nonfree
  software-properties-common
  vim
  jq
  xclip
  btop
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
  virtualbox-ext-pack
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

service dnsmasq restart
service resolvconf restart

### Start steam and login ###
# Detect the Linux distribution
installs2=(
  mesa-vulkan-drivers
  libglx-mesa0:i386
  mesa-vulkan-drivers:i386
  libgl1-mesa-dri:i386
  libgtk2.0-0:i386
  )
for package in "${installs2[@]}"; do
    if ! dpkg-query -Wf'${db:Status-abbrev}' "$package" 2>/dev/null | grep -q '^i'; then
        sudo apt install "$package" -y || { echo "Failed to install $package"; exit 1; }
    fi
done
if grep -iq "Ubuntu" /etc/os-release; then
    # This is an Ubuntu system
    # Installing Steam
    sudo apt install steam -y
elif grep -iq "Debian" /etc/os-release; then
    # This is a Debian system
    # Enable the "non-free" and "contrib" repositories for Debian to install Steam
    echo "deb http://deb.debian.org/debian/ $(lsb_release -cs) main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/non-free.list
    echo "deb-src http://deb.debian.org/debian/ $(lsb_release -cs) main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/non-free.list

    # Update the package list again after adding non-free and contrib repositories
    sudo apt update

    # Installing Steam Installer
    sudo apt install steam-installer -y
else
    echo "This script is intended for Ubuntu and Debian only."
    exit 1
fi
#Steam-installer will install Steam to ~/.steam/debian-installation to run Steam, you will need to run the shell script located in this directory.
~/.steam/debian-installation/steam.sh
#fix errors from steam runtime
find ~/.steam/root/ \( -name "libgcc_s.so*" -o -name "libstdc++.so*" -o -name "libxcb.so*" \) -print -delete
#By default, it will also use newer versions of certain libraries from the host system if available. You can disable this functionality, and force utilization of the older Steam runtime, by running Steam with:
STEAM_RUNTIME_PREFER_HOST_LIBRARIES=0 steam
#Run these commands to remove runtime libraries known to cause issues with Debian:
rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/usr/lib/i386-linux-gnu/libstdc++.so.6
rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/lib/i386-linux-gnu/libgcc_s.so.1
rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/amd64/lib/x86_64-linux-gnu/libgcc_s.so.1
rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/amd64/usr/lib/x86_64-linux-gnu/libstdc++.so.6
rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/usr/lib/i386-linux-gnu/libxcb.so.1
rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/lib/i386-linux-gnu/libgpg-error.so.0m
#It's also necessary to link two libraries because the libudev.so.0 file is currently not available in Debian:
ln -s /lib/i386-linux-gnu/libudev.so.1 /lib/i386-linux-gnu/libudev.so.0
LD_LIBRARY_PATH=~/.steam/bin32 ldd ~/.steam/bin32/steamclient.so | grep 'not found'
#no sound in games
rm -rf ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/usr/lib/i386-linux-gnu/alsa-lib
rm -rf ~/.steam/debian-installation/ubuntu12_32/steam-runtime/amd64/usr/lib/x86_64-linux-gnu/alsa-lib
rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/i386/usr/lib/i386-linux-gnu/libasound.so.*
rm ~/.steam/debian-installation/ubuntu12_32/steam-runtime/amd64/usr/lib/x86_64-linux-gnu/libasound.so.*
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

#!/bin/bash

sudo apt --fix-broken install -y
sudo apt purge firefox -y

# Check if Snap is installed before trying to remove Firefox with Snap
if command -v snap &> /dev/null
then
    sudo snap remove --purge firefox
fi
# Check if system is Ubuntu before adding PPA
if grep -iq "Ubuntu" /etc/os-release; then
    if ! grep -q "^deb .*mozillateam/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
      sudo add-apt-repository ppa:mozillateam/ppa -y
    fi
    sudo tee /etc/apt/preferences.d/Mozilla <<EOF
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:'$(lsb_release -cs)'";' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
fi
sudo apt update
sudo apt install firefox -y


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
# Detect the distribution
if grep -iq "Ubuntu" /etc/os-release; then
    # This is an Ubuntu system
    sudo add-apt-repository multiverse -y
elif grep -iq "Debian" /etc/os-release; then
    # This is a Debian system
    # Enable contrib and non-free repositories if not already enabled
    sudo sed -i '/ main$/ s/$/ contrib non-free/' /etc/apt/sources.list
fi
sudo apt update
sudo apt upgrade -y
sudo fc-cache -f -v
# Install language support and Microsoft Fonts if available
if command -v check-language-support &> /dev/null; then
    sudo apt install $(check-language-support) ttf-mscorefonts-installer -y
else
    echo "check-language-support command not found, installing fonts only."
    sudo apt install ttf-mscorefonts-installer -y
fi

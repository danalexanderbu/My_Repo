#!/bin/bash

function apt_installs() {
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
        timeshift
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
    sudo apt remove --purge kwalletmanager
    sudo apt update -y && sudo apt upgrade -y
}

function download_and_install_deb() {
    declare -a urls=(
    "https://az764295.vo.msecnd.net/stable/704ed70d4fd1c6bd6342c436f1ede30d1cff4710/code_1.77.3-1681292746_amd64.deb"
    "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    "https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb"
    "https://cdn.zoom.us/prod/5.15.12.7665/zoom_amd64.deb"
    "http://ftp.us.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_20230311_all.deb"
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
}

function install_btop() {
    latest_release_btop=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest | jq -r .assets[11].browser_download_url)
    btop_file_name=$(basename "$latest_release_btop")
    wget "$latest_release_btop" -O "$btop_file_name"
    tar -xjf "$btop_file_name"
    cd btop
    ./install.sh
    cd $HOME
    rm -r "$btop_file_name"
}

function install_firefox() {
    sudo apt remove firefox-esr -y && sudo apt purge firefox-esr -y
    sudo gpg --keyserver keyserver.ubuntu.com --recv-keys 2667CA5C
    sudo gpg -ao ~/ubuntuzilla.gpg --export 2667CA5C
    cat ubuntuzilla.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/ubuntuzilla.gpg
    sudo rm ~/ubuntuzilla.gpg
    echo "deb [signed-by=/etc/apt/keyrings/ubuntuzilla.gpg] http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main" | sudo tee /etc/apt/sources.list.d/ubuntuzilla.list > /dev/null
    sudo apt update -y && sudo apt upgrade -y
    sudo apt install firefox-mozilla-build -y
}

echo "Select which sections to install:"
echo "1. APT Installs"
echo "2. Download and Install DEB Packages"
echo "3. Install Btop"
echo "4. Install Firefox Browser"
echo "5. Install CAC"
echo "6. Install Kubernetes"
echo "7. Install Brave Browser"
echo "8. All"
echo -n "Enter your choice (e.g., 1 2 3): "
read -a choices

for choice in "${choices[@]}"; do
    case $choice in
        1) apt_installs;;
        2) download_and_install_deb;;
        3) install_btop;;
        4) install_firefox;;
        5) install_cac;;
        6) install_kubernetes;;
        7) install_brave;;
        8) apt_installs; download_and_install_deb; install_btop; install_firefox; install_cac; install_kubernetes; install_brave;;
        *) echo "Invalid option: $choice";;
    esac
done
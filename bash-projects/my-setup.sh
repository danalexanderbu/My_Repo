#!/bin/bash
#Intended to give the user a choice of what to install on a fresh debian install or to update an existing install
#This script has some parts intended for root and some for the user
#The apt_installs function is intended to be run as root and can be updated to include more packages
#The update_firefox function is intended to be run as root as Debian does not allow the user to update firefox automatically
#This has been tested on Debian 12 (Bookworm)
#If you have a problem with CAC setup try opening firefox and chrome and then rerunning the script
function blacklist_nouveau() {
    # Inform the user about the action being taken
    echo "The nouveau driver will be blacklisted. This should be checked if using an Nvidia GPU."

    # Blacklist the nouveau driver
    echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
    echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf

    # Update initramfs
    sudo update-initramfs -u
}

function add_repositories() {
     # Display a notice about the action being taken
    echo "Adding non-free and contrip repositories"
    
    sudo add-apt-repository non-free -y
    sudo add-apt-repository contrib non-free -y
}

function apt_installs() {
    declare -a packages=(\
        "libpcsclite1" "PC/SC Lite shared library" ON \
        "pcscd" "Middleware to access a smart card" ON \
        "libccid" "PC/SC driver for USB CCID smart card readers" ON \
        "libpcsc-perl" "Perl bindings for PC/SC" ON \
        "pcsc-tools" "Tools for testing PC/SC drivers and applications" ON \
        "libnss3-tools" "Network Security Service tools" ON \
        "ffmpeg" "Multimedia player, server and encoder" OFF \
        "obs-studio" "Open broadcaster software studio" ON \
        "openssl" "Secure Sockets Layer toolkit" ON \
        "qbittorrent" "Free and reliable P2P BitTorrent client" ON \
        "ttf-mscorefonts-installer" "Installer for Microsoft TrueType core fonts" ON \
        "python3" "Python 3 interpreter" ON \
        "googler" "Google from the terminal" ON \
        "python3-pip" "Python package installer" ON \
        "vim" "Vi IMproved - enhanced vi editor" ON \
        "ethtool" "Utility for controlling network drivers and hardware" ON \
        "net-tools" "Networking tools" ON \
        "nmap" "Network exploration tool and security scanner" ON \
        "jq" "Json Query language interpreter" ON \
        "compton" "Compositor for AwesomeWM" OFF \
        "gnome-themes-extra" "GNOME extra themes" ON \
        "nitrogen" "Wallpaper manager for AwesomeWM" OFF \
        "dmenu" "Better menu for startup in AwesomeWM" OFF\
        "samba" "SMB/CIFS file, print, and login server for Unix" ON \
        "gnome-keyring" "GNOME keyring services" ON \
        "apt-transport-https" "APT transport for downloading via the HTTPS protocol" ON \
        "docker.io" "Container platform tool" ON \
        "gnupg2" "GNU privacy guard - modern version" ON \
        "ebtables" "Ethernet bridge frame table administration" ON \
        "aria2" "High speed download utility" ON \
        "ca-certificates" "Common CA certificates" ON \
        "timeshift" "System restore tool for Linux" ON \
        "nfs-common" "NFS support files common to client and server" ON \
        "neofetch" "System information tool" ON \
        "curl" "Command line tool for transferring data with URL syntax" ON \
        "lsb-release" "Linux Standard Base version reporting utility" ON \
        "unattended-upgrades" "Automatic installation of security upgrades" ON \
        "mlocate" "Faster locate using database" ON \
        "kwalletmanager" "KDE wallet manager" OFF \
        "plasma-discover" "KDE Discover software store" OFF \
        "plasma-discover-snap-backend" "Snap backend for KDE Discover" OFF
    )

    for ((i=0; i<${#packages[@]}; i+=3)); do
        if [ "${packages[i+2]}" == "ON" ]; then
            pkg=${packages[i]}
            if ! dpkg-query -Wf'${db:Status-abbrev}' "$pkg" 2>/dev/null | grep -q '^i'; then
                sudo apt install "$pkg" -y || { echo "Failed to install $pkg"; exit 1; }
            fi
        fi
    done
    echo "Installed ${packages[@]}"

}

function_awesomewm() {
    sudo apt install awesome nitrogen compton dmenu alacritty -y
    mkdir -p ~/.config/awesome
    mkdir -p ~/.config/alacritty
    mkdir -p /usr/share/icons
    sudo cp -r ~/Documents/My_Repo/awesome/Arc ~/usr/share/icons/Arc
    sudo cp ~/Documents/My_Repo/awesome/alacritty/alacritty.yml ~/.config/alacritty/alacritty.yml
    sudo cp ~/Documents/My_Repo/awesome/rc.lua ~/.config/awesome/rc.lua
    sudo cp ~/Documents/My_Repo/awesome/json.lua ~/.config/awesome/json.lua
    sudo cp -r ~/Documents/My_Repo/awesome/icons ~/.config/awesome/icons/
    sudo cp -r ~/Documents/My_Repo/awesome/themes ~/.config/awesome/themes/
    sudo cp -r ~/Documents/My_Repo/awesome/wallpapers ~/.config/wallpapers/
    sudo cp -r ~/Documents/My_Repo/awesome/awesome-wm-widgets ~/.config/awesome/awesome-wm-widgets
    sudo cp  ~/Documents/My_Repo/awesome/compton.conf ~/.config/compton.conf
    sudo cp  ~/Documents/My_Repo/awesome/display.sh ~/.config/display.sh
    cat << EOF > /usr/share/xsessions/awesome.desktop
    [Desktop Entry]
    Name=awesome
    Comment=Highly configurable framework window manager
    TryExec=awesome
    Exec=awesome
    Type=Application
    Icon=/usr/share/pixmaps/awesome.xpm
    Keywords=Window manager
EOF
}

function remove_packages() {
    local installed_packages=(
        "libpcsclite1" "PC/SC Lite shared library" OFF \
        "pcscd" "Middleware to access a smart card" OFF \
        "libccid" "PC/SC driver for USB CCID smart card readers" OFF \
        "libpcsc-perl" "Perl bindings for PC/SC" OFF \
        "pcsc-tools" "Tools for testing PC/SC drivers and applications" OFF \
        "libnss3-tools" "Network Security Service tools" OFF \
        "ffmpeg" "Multimedia player, server and encoder" OFF \
        "obs-studio" "Open broadcaster software studio" OFF \
        "openssl" "Secure Sockets Layer toolkit" OFF \
        "qbittorrent" "Free and reliable P2P BitTorrent client" OFF \
        "ttf-mscorefonts-installer" "Installer for Microsoft TrueType core fonts" OFF \
        "python3" "Python 3 interpreter" OFF \
        "python3-pip" "Python package installer" OFF \
        "vim" "Vi IMproved - enhanced vi editor" OFF \
        "ethtool" "Utility for controlling network drivers and hardware" OFF \
        "net-tools" "Networking tools" OFF \
        "nmap" "Network exploration tool and security scanner" OFF
        "samba" "SMB/CIFS file, print, and login server for Unix" OFF \
        "gnome-keyring" "GNOME keyring services" OFF \
        "gnome-themes-extra" "GNOME extra themes" OFF \
        "apt-transport-https" "APT transport for downloading via the HTTPS protocol" OFF \
        "docker.io" "Container platform tool" OFF \
        "gnupg2" "GNU privacy guard - modern version" OFF \
        "ebtables" "Ethernet bridge frame table administration" OFF \
        "aria2" "High speed download utility" OFF \
        "thunderbird" "Email, news and chat client from Mozilla" OFF \
        "awesome" "highly configurable, next generation framework window manager for Debian 12" OFF \
        "nitrogen" "wallpaper browser and changing utility for Debian 12" OFF \
        "dmenu" "dynamic menu for Debian 12" OFF \
        "compton" "X11 compositor for Debian 12" OFF \
        "ufw" "Uncomplicated Firewall" OFF \
        "timeshift" "System restore tool for Linux" OFF \
        "nfs-common" "NFS support files common to client and server" OFF \
        "neofetch" "System information tool" OFF \
        "curl" "Command line tool for transferring data with URL syntax" OFF \
        "lsb-release" "Linux Standard Base version reporting utility" OFF \
        "unattended-upgrades" "Automatic installation of security upgrades" OFF \
        "kwalletmanager" "KDE wallet manager" OFF \
        "plasma-discover" "KDE Discover software store" OFF \
        "plasma-discover-snap-backend" "Snap backend for KDE Discover" OFF
        "brave-browser" "Brave browser" OFF \
        "google-chrome-stable" "Google Chrome" OFF \
        "firefox" "Firefox" OFF \
        "thorium-browser" "Thorium browser" OFF \
        "mullvad-vpn" "Mullvad browser" OFF \
    )
       
# List of packages to remove
    local to_remove=()

    # Check which packages are installed and should be removed
    for ((i=0; i<${#installed_packages[@]}; i+=3)); do
        if [ "${installed_packages[i+2]}" == "OFF" ]; then
            pkg="${installed_packages[i]}"
            if dpkg-query -Wf'${db:Status-abbrev}' "$pkg" 2>/dev/null | grep -q '^i'; then
                to_remove+=("$pkg")
            fi
        fi
    done

    # Check if there are packages to remove
    if [ ${#to_remove[@]} -eq 0 ]; then
        echo "No packages to remove."
        return
    fi

    echo "Removing the following packages: ${to_remove[*]}"
    for pkg in "${to_remove[@]}"; do
        sudo apt remove --purge "$pkg" -y || { echo "Failed to remove $pkg"; exit 1; }
    done

    sudo apt autoremove -y
}

function download_and_install_deb() {
    cd $HOME/Downloads
    declare -a urls=(
        "https://dl.discordapp.net/apps/linux/0.0.25/discord-0.0.25.deb"
        "https://az764295.vo.msecnd.net/stable/704ed70d4fd1c6bd6342c436f1ede30d1cff4710/code_1.77.3-1681292746_amd64.deb"
        "https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb"
        "https://updates.torguard.biz/Software/Linux/torguard-latest-amd64.deb"
        "https://cdn.zoom.us/prod/5.15.12.7665/zoom_amd64.deb"
        "http://repo.steampowered.com/steam/archive/precise/steam_latest.deb"
    )

    echo "Please select the package you want to download and install. Enter number (e.g., 1) or 0 to exit:"
    select package_url in "${urls[@]}" "Exit"; do
        case $package_url in
            "Exit")
                echo "Exiting."
                break
                ;;
            *)
                file_name=$(basename "$package_url")
                wget "$package_url" -O "$file_name"
                echo "Successfully downloaded $file_name"
                sudo dpkg -i "$file_name" && sudo apt --fix-broken install -y
                echo "Successfully installed $file_name"
                rm "$file_name"
                ;;
        esac
        echo "Do you want to download and install another package? [y/n]"
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
            break
        fi
    done

    sudo apt update -y && sudo apt --fix-broken install && sudo apt upgrade -y
    cd $HOME
}

function install_kubernetes() {
    #install kubernetes with kubeadm and containerd
    curl  -fsSL  https://packages.cloud.google.com/apt/doc/apt-key.gpg|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes.gpg
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt update
    sudo apt install kubelet kubeadm kubectl -y
    sudo apt-mark hold kubelet kubeadm kubectl
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    sudo swapoff -a
    # Enable kernel modules
    sudo modprobe overlay
    sudo modprobe br_netfilter

    # Add some settings to sysctl
    sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
EOF

    # Reload sysctl
    sudo sysctl --system
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y containerd.io
    sudo mkdir -p /etc/containerd
    sudo containerd config default|sudo tee /etc/containerd/config.toml
    sudo systemctl restart containerd
    sudo systemctl enable containerd
    systemctl status  containerd
    sudo systemctl enable kubelet
    sudo systemctl start kubelet
    sudo kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock
    sudo sysctl -p
    sudo kubeadm init > ~/kubeadm-init.log
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    echo "View https://www.linuxtechi.com/install-kubernetes-cluster-on-debian/ for debuging and full nodes setup"
}

function install_btop() {
    local response
    echo "Do you want to download and install the latest version of btop? [y/n]"
    read -r response

    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        cd $HOME/Downloads
        latest_release_btop=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest | jq -r .assets[11].browser_download_url)
        
        # Check if the curl command was successful
        if [ $? -ne 0 ]; then
            echo "Failed to fetch the latest release URL for btop."
            return 1
        fi
        
        btop_file_name=$(basename "$latest_release_btop")
        wget "$latest_release_btop" -O "$btop_file_name"
        
        # Check if the wget command was successful
        if [ $? -ne 0 ]; then
            echo "Failed to download the btop package."
            return 1
        fi
        
        echo "Successfully downloaded $btop_file_name"
        
        tar -xjf "$btop_file_name"
        cd btop
        ./install.sh
        
        # Check if the installation was successful
        if [ $? -ne 0 ]; then
            echo "Failed to install btop."
            return 1
        fi
        
        echo "Successfully installed btop"
        
        cd $HOME/Downloads
        rm -r "$btop_file_name"
    else
        echo "btop installation cancelled."
    fi
    sudo apt --fix-broken install -y
}

function install_firefox() {
    local response
    echo "This will update Firefox to the latest version. Do you want to continue? [y/n]"
    read -r response

    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        cd $HOME/Downloads
        pkill firefox || true
        URL="https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US"
        wget -O firefox-latest.tar.bz2 "$URL"
        tar xjf firefox-latest.tar.bz2
        TIMESTAMP=$(date +"%Y%m%d%H%M%S")
        if [ -d "/opt/firefox" ]; then
            sudo mv /opt/firefox /opt/firefox.bak.$TIMESTAMP
        fi
        sudo mkdir -p /opt/firefox
        sudo cp -r $HOME/Downloads/firefox/* /opt/firefox
        rm -rf $HOME/Downloads/firefox-latest.tar.bz2 $HOME/Downloads/firefox
        echo "Firefox has been updated to the latest version."
    else
        echo "Update canceled by user"
    fi
}


function install_thorium-browser() {
    local response
    echo "This will install Thorium web browser. Do you want to continue? [y/n]"
    read -r response

    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        cd $HOME/Downloads
        wget https://dl.thorium.rocks/debian/dists/stable/thorium.list && sudo mv thorium.list /etc/apt/sources.list.d/ && sudo apt update
        sudo apt install thorium-browser -y
        echo "Thorium web browser has been installed successfully."
        cd $HOME
    else
        echo "Installation canceled by user."
    fi
    sudo apt --fix-broken install -y
}


function install_google-chrome() {
    local response
    echo "This will install Google Chrome. Do you want to continue? [y/n]"
    read -r response

    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        cd $HOME/Downloads
        curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o google-chrome-stable_current_amd64.deb
        sudo dpkg -i google-chrome-stable_current_amd64.deb
        rm google-chrome-stable_current_amd64.deb
        sudo apt --fix-broken install -y
        echo "Google Chrome has been installed successfully."
    else
        echo "Installation canceled by user."
    fi
}

function install_mullvad-browser () {
    local response
    echo "This will install Mullvad VPN. Do you want to continue? [y/n]"
    read -r response

    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        cd $HOME/Downloads
        wget https://mullvad.net/en/download/browser/linux-x86_64/latest -O mullvad-browser-linux-x86_64.tar.xz
        tar -xvf mullvad-browser-linux-x86_64.tar.xz
        sudo mkdir -p /opt/mullvad-browser
        sudo cp -r $HOME/Downloads/mullvad-browser/* /opt/mullvad-browser
        sudo chown -R $(whoami):$(whoami) /opt/mullvad-browser
        sudo updatedb
        rm -r mullvad-browser-linux-x86_64.tar.xz
        sudo tee /usr/share/applications/mullvad-browser.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Mullvad Browser
Comment=Private and secure web browser by Mullvad
Exec=/opt/mullvad-browser/Browser/start-mullvad-browser %u
Icon=/opt/mullvad-browser/Browser/browser/chrome/icons/default/default64.png
Terminal=false
Categories=Network;WebBrowser;
EOF
        sudo chmod +x /usr/share/applications/mullvad-browser.desktop
        echo "Mullvad-browser installed successfully! Please make sure to logout or restart to use the browser."
    else
        echo "Installation canceled by user."
    fi
}

function install_brave-browser () {
    local response
    echo "This will install Brave browser. Do you want to continue? [y/n]"
    read -r response

    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        sudo apt update -y && sudo apt install brave-browser -y
        sudo apt --fix-broken install -y
    else
        echo "Installation canceled by user"
    fi
}

function install_cac () {
    cd $HOME/Downloads
    wget https://raw.githubusercontent.com/danalexanderbu/My_Repo/master/bash-projects/deb_cac_setup.sh && chmod +x deb_cac_setup.sh && sudo ./deb_cac_setup.sh
}

function install_flatpak_and_bottles () {
    local response
    echo "This will install Flatpak and Bottles. Do you want to continue? [y/n]"
    read -r response

    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        sudo apt install flatpak -y
        sudo apt install plasma-discover-backend-flatpak -y
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        flatpak install flathub com.usebottles.bottles -y
    else
        echo "Installation canceled by user"
    fi
    sudo apt --fix-broken install -y
}

function install_protonGE () {
    if ! command -v steam &> /dev/null; then
        echo "Steam is not installed. Please install Steam first."
        return 1
    fi

    for cmd in curl jq steam; do
        if ! command -v $cmd &> /dev/null; then
            echo "$cmd could not be found. Please install it and try again."
            return 1
        fi
    done

    local response
    echo "Do you want to install Proton GE? [y/n]"
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
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
            echo "Proton GE ($folder_name) has been installed successfully."
        fi
    else
        echo "Installation cancelled by user."
    fi
}

function install_obsidian () {
    for cmd in curl jq; do
        if ! command -v $cmd &> /dev/null; then
            echo "$cmd could not be found. Please install it and try again."
            return 1
        fi
    done

    local response
    echo "Do you want to install Obsidian? [y/n]"
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        latest_release_url_Obsidian=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
        wget "$latest_release_url_Obsidian"
        file_name=$(basename "$latest_release_url_Obsidian")
        sudo dpkg -i "$file_name"
        rm "$file_name"
        sudo apt --fix-broken install -y
        echo "Obsidian has been installed successfully."
    else
        echo "Installation cancelled by user."
    fi
}


function install_virtualbox () {
    local response
    echo "Do you want to install VirtualBox? [y/n]"
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        cd $HOME/Downloads
        # Add the Oracle VBox 2016 public key
        if dpkg -l | grep virtualbox > /dev/null; then
            echo "VirtualBox is already installed. Do you want to continue and reinstall? [y/n]"
            read -r response
            if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
                echo "Exiting script."
                return 0
            fi
        fi
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
        # Install latest version of VirtualBox
        VB_LATEST_VERSION=$(curl -s https://www.virtualbox.org/wiki/Downloads | grep -oP 'VirtualBox-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        sudo apt install virtualbox-$VB_LATEST_VERSION -y
        # Download the latest Oracle VM VirtualBox Extension Pack
        LATEST_VERSION=$(curl -s https://www.virtualbox.org/wiki/Downloads | grep -oP 'Oracle_VM_VirtualBox_Extension_Pack-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        wget "https://download.virtualbox.org/virtualbox/$LATEST_VERSION/Oracle_VM_VirtualBox_Extension_Pack-$LATEST_VERSION.vbox-extpack" -O "Oracle_VM_VirtualBox_Extension_Pack-$LATEST_VERSION.vbox-extpack"
        # Install the Oracle VM VirtualBox Extension Pack
        sudo vboxmanage extpack install "Oracle_VM_VirtualBox_Extension_Pack-$LATEST_VERSION.vbox-extpack"
        # Remove the downloaded Oracle VM VirtualBox Extension Pack
        rm "Oracle_VM_VirtualBox_Extension_Pack-$LATEST_VERSION.vbox-extpack"
        # Add the current user to the vboxusers group to grant permission to access the vboxdrv kernel module and Change the user’s group to vboxusers for the current session
        sudo usermod -aG vboxusers $USER && newgrp vboxusers
        echo "Please log out and log back in to apply the group changes."
    fi
}


function install_python_packages () {
    for cmd in python3 pip3; do
        if ! command -v $cmd &> /dev/null; then
            echo "$cmd could not be found. Please install it and try again."
            return 1
        fi
    done

    local response
    echo "Do you want to install the Python packages? [y/n]"
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
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
        # More efficient way to install python packages than for loop
        pip3 install "${packages[@]}" --break-system-packages
        echo "Python packages installed successfully."
    fi
}

function install_git () {
    #make git from source to enable openssl windows support on linux
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
    sudo apt install curl jq -y
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
    local name
    local email
    # Use read instead of whiptail for getting the name
    read -p "Please enter your name: " name
    if [ -z "$name" ]; then
        return
    fi
    # Use read instead of whiptail for getting the email
    read -p "Please enter your email: " email
    if [ -z "$email" ]; then
        return
    fi
    git config --global core.editor "code"
    #git config --global http.sslCAInfo ~/.mycerts/dod_cert_bundle.pem
    git config --global http.sslverify false
    git config --global http.sslverify true
    # Define the path to the Documents directory
    DOCUMENTS_DIR="$HOME/Documents"
    # Go to the Documents directory
    cd "$DOCUMENTS_DIR" || { echo "Failed to switch to the Documents directory"; exit 1; }
    # Check if SSH Key already exists
    # Check if SSH Key already exists
    local ssh_key_path=~/.ssh/github_ssh_key.pub
    local ssh_key
    if [ ! -f "$ssh_key_path" ]; then
        # 1. Generate SSH Key (without passphrase for automation; you can modify as needed)
        ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/github_ssh_key || { echo "SSH key generation failed"; exit 1; }
        ssh_key=$(cat "$ssh_key_path")
        echo "Please add the following SSH key to your GitHub account:\n\n$ssh_key"
    else
        ssh_key=$(cat "$ssh_key_path")
        echo "SSH key already exists:\n\n$ssh_key"
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
}

function install_theme () {
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

    git clone https://github.com/ryanoasis/nerd-fonts.git
    cd nerd-fonts
    ./install.sh
    # update font cache
    sudo fc-cache -f -v
    cd $HOME

}

function configure_bashrc () {
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
    alias uu="sudo apt update && sudo apt upgrade"

    #Kubernetes alias
    alias k="kubectl"
    alias kg="kubectl get"
    alias kdes="kubectl describe"
    alias ki="kubectl delete"

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
}


function enable_UFW () {
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
    sudo ufw allow from 192.168.1.133 to any port 137
    sudo ufw allow from 192.168.1.133 to any port 445
    #Allow steam
    sudo ufw allow 27000:27050/udp
    sudo ufw allow 27000:27050/tcp
    sudo ufw allow 27015:27030/udp
    sudo ufw allow 27036:27037/tcp
    sudo ufw allow 27031:27036/udp
    sudo ufw allow 4380/udp
    sudo ufw reload
}

function custom_fstab () {
    #Backup fstab
    sudo cp /etc/fstab /etc/fstab.bak
    #Add fstab entries
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    sudo tee -a /etc/fstab <<EOF
    192.168.1.133:/mnt/user/Movies	/mnt/Movies	nfs	defaults	0	0
    192.168.1.133:/mnt/user/TV	/mnt/TV		nfs	defaults	0	0
    192.168.1.133:/mnt/user/Downloads	/mnt/Downloads	nfs	defaults	0	0
    192.168.1.133:/mnt/user/Disney\040Movies	/mnt/Disney\040Movies	nfs	defaults 0	0
EOF
}

#error handling when a function fails
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOGFILE="install_log_${TIMESTAMP}.txt"
ERRORFILE="errors_${TIMESTAMP}.txt"
function function_status() {
    local func_name="$1"
    if $func_name; then
        echo "$func_name completed successfully." | tee -a $LOGFILE
    else
        echo "Error executing $func_name." | tee -a $LOGFILE
        return 1
    fi
}

while true; do
    echo "Choose an option:"
    echo "1 - Blacklist Nouveau"
    echo "2 - Add Repositories"
    echo "3 - Install Packages"
    echo "4 - Remove Packages"
    echo "5 - Download and Install .deb"
    echo "6 - Install btop"
    echo "7 - Install Firefox"
    echo "8 - Install Brave"
    echo "9 - Install Chrome"
    echo "10 - Install Mullvad"
    echo "11 - Install Thorium"
    echo "12 - Update Firefox"
    echo "13 - Install Flatpak and Bottles"
    echo "14 - Install ProtonGE"
    echo "15 - Install Obsidian"
    echo "16 - Install VirtualBox"
    echo "17 - Install Python Packages"
    echo "18 - Install Git"
    echo "19 - Install Theme"
    echo "20 - Configure .bashrc"
    echo "21 - Enable UFW"
    echo "22 - Install CaC certs"
    echo "23 - Install Kubernetes"
    echo "24 - Customise fstab"
    echo "25 - Exit"
    read -p "Enter your choice: " choice
    
    case $choice in
        1) function_status blacklist_nouveau;;
        2) function_status add_repositories;;
        3) function_status apt_installs;;
        4) function_status remove_packages;;
        5) function_status download_and_install_deb;;
        6) function_status install_btop;;
        7) function_status install_firefox-browser;;
        8) function_status install_brave-browser;;
        9) function_status install_google-chrome;;
        10) function_status install_mullvad-browser;;
        11) function_status install_thorium-browser;;
        12) function_status update_firefox;;
        13) function_status install_flatpak_and_bottles;;
        14) function_status install_protonGE;;
        15) function_status install_obsidian;;
        16) function_status install_virtualbox;;
        17) function_status instal_python_packages;;
        18) function_status install_git;;
        19) function_status install_theme;;
        20) function_status configure_bashrc;;
        21) function_status enable_UFW;;
        22) function_status install_cac;;
        23) function_status install_kubernetes;;
        24) function_status custom_fstab;;
        25) echo "Exiting script."; break;;
        *) echo "Invalid option: $choice";;
    esac

    # Check if the user wants to exit
    if [ "$choice" = "23" ]; then
        echo "Exiting script."
        break
    fi
done

awk '/Error executing/ {print $0}' $LOGFILE > $ERRORFILE

echo "Script execution completed. Check $LOGFILE for details."
if [[ -s $ERRORFILE ]]; then
    echo "Some errors were encountered. Check $ERRORFILE for details."
else
    echo "No errors were encountered."
fi

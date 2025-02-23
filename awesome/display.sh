#!/bin/bash

# Define your wallpaper directory
WALLPAPER_DIR="$HOME/.config/wallpapers"


# Function to set a random wallpaper using Nitrogen
set_random_wallpaper() {
    local head=$1
    local wallpaper_dir=$2
    local random_wallpaper=$(ls "$wallpaper_dir" | shuf -n 1)
    
    if [[ -f "$wallpaper_dir/$random_wallpaper" ]]; then
        nitrogen --set-scaled --head=$head --save "$wallpaper_dir/$random_wallpaper"
    fi
}

# Set HDMI-0
xrandr --output HDMI-0 --mode 1920x1080 --pos 2117x0 --rate 165 --rotate normal
sleep 0.1
set_random_wallpaper 2 $WALLPAPER_DIR
# Set DP-2 to the left of DP-0
xrandr --output DP-2 --mode 1920x1080 --pos 0x1080 --rate 144 --rotate normal
sleep 0.1
set_random_wallpaper 1 $WALLPAPER_DIR

# Set DP-0 as the center display
xrandr --output DP-0 --primary --mode 2560x1440 --pos 1920x1080 --rate 165 --rotate normal
sleep 0.1
set_random_wallpaper 0 $WALLPAPER_DIR

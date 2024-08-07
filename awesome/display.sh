#!/bin/bash

# Define your wallpaper directory
WALLPAPER_DIR="$HOME/.config/wallpapers"

# Function to set a random wallpaper using Nitrogen
set_random_wallpaper() {
    local display=$1
    local wallpaper_dir=$2
    local random_wallpaper=$(ls $wallpaper_dir | shuf -n 1)
    nitrogen --set-scaled --head=$display --save "$wallpaper_dir/$random_wallpaper"
}

# Set up the middle display (DP-4) and random wallpaper
xrandr --output DP-4 --primary --mode 2560x1440 --pos 1920x0 --rate 165 --rotate normal
sleep 0.1
set_random_wallpaper 0 $WALLPAPER_DIR

# Set up the left display (DP-0) and random wallpaper
xrandr --output DP-0 --mode 1920x1080 --pos 0x280 --rate 144 --rotate normal
sleep 0.1
set_random_wallpaper 1 $WALLPAPER_DIR

# Set up the right display (DP-2) and random wallpaper
xrandr --output DP-2 --mode 1920x1080 --pos 4480x360 --rate 165 --rotate normal
sleep 0.1
set_random_wallpaper 2 $WALLPAPER_DIR

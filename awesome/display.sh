#!/bin/bash

# Set up the left display (DP-4)
xrandr --output DP-4 --mode 1920x1080 --pos 0x280 --rate 144 --rotate normal

# Set up the middle display (DP-2)
xrandr --output DP-2 --primary --mode 2560x1440 --pos 1920x0 --rate 165 --rotate normal

# Set up the right display (DP-0)
xrandr --output DP-0 --mode 1920x1080 --pos 4480x360 --rate 165 --rotate normal

#!/bin/bash
#           _                 _ _
#  ___  ___| |___      ____ _| | |
# / __|/ _ \ __\ \ /\ / / _` | | |
# \__ \  __/ |_ \ V  V / (_| | | |
# |___/\___|\__| \_/\_/ \__,_|_|_|
#
# Author: Nick Clyde
#
# Script to generate colorschemes and set wallpapers across system.
# Will use a random file from $HOME/Wallpapers if no arg is passed
# Run this at startup, i.e. on i3: exec_always --no-startup-id /path/to/this/script
# Thanks to Daniel Stevenson (https://gitlab.com/snippets/1842628)
#
# Depends on:
#   Arch repositories: python-pywal
#   AUR: wpgtk-git

# Choose a random file from $HOME/Wallpapers if no arg passed
if [ $# -eq 0 ] ; then
    files=($HOME/Wallpapers/*)
    wall=$(printf "%s\n" "${files[RANDOM % ${#files[@]}]}")
else
    # Get absolute path of file passed in arg
    wall=$(readlink -f $1)
    if [ ! -f "$wall" ]; then
        echo "File not found!"
        exit 1
    fi
    # Use alternate backend if specified
    if [ ! -z "$2" ]; then
        backend="--backend $2"
        echo "Using $2 backend"
    fi
fi
filename=$(basename -- "$wall")
extension="${filename##*.}"
filename="${filename%.*}"

WALCACHE=$HOME/.cache/wal

# Remove the old thumbnail and colorschemes so they are properly updated
rm -f $HOME/.config/wpg/schemes/*.json
rm -f $WALCACHE/schemes/*.json
wal -c

# Generate and set a theme based on the wallpaper with wpgtk.
# Remember to have your GTK theme set to FlatColor or this won't work correctly!
# We don't need to set the wallpaper.
wpg -A $wall $backend
wpg -ns $wall $backend

# Generate the theme again with pywal, as wpg misses some things and doesn't do as good of a job in general.
# You could use this without wpg, but it will not set the GTK theme.
wal -i $wall $backend
rm -f $HOME/Wallpapers/*_sample.png

# Update konsole colorscheme
cp $WALCACHE/colors-konsole.colorscheme $HOME/.local/share/konsole

# Update colors.css for Firefox userChrome.css
cp $WALCACHE/colors.css $HOME/.mozilla/firefox/b5e0xjzo.default-release/chrome/colors.css

# Update atom colors
cp $WALCACHE/colors-atom-syntax $HOME/.atom/packages/wal-syntax/styles/colors.less

# Update dunst colors
cp $WALCACHE/colors-dunst $HOME/.config/dunst/dunstrc
killall dunst && i3 restart > /dev/null

# Set the wallpaper with feh
feh --no-xinerama --bg-fill $wall

# Set the wallpaper for sddm
SDDM_THEME_PATH=/usr/share/sddm/themes/McMojave
cp $wall $SDDM_THEME_PATH/bg.$extension
cp $SDDM_THEME_PATH/theme.conf.user $SDDM_THEME_PATH/theme.conf.user.bak
cat $SDDM_THEME_PATH/theme.conf.user | sed -E "s/background=.*/background=bg.$extension/" > /tmp/theme.conf.user
cp /tmp/theme.conf.user $SDDM_THEME_PATH/theme.conf.user

# Set the wallpaper for kscreenlocker
cp $HOME/.config/kscreenlockerrc $HOME/.config/kscreenlockerrc.bak
cat $HOME/.config/kscreenlockerrc | sed -E "s@Image=.*@Image=file://$wall@" > /tmp/kscreenlockerrc
cp /tmp/kscreenlockerrc $HOME/.config/kscreenlockerrc

# Notify
nid=$(dunstify -i $wall -p "Wallpaper set to $filename")

# Close useless notifications
dunstify -C $((nid-1))
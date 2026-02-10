#!/bin/bash
#    ____         __       ____               __     __
#   /  _/__  ___ / /____ _/ / / __ _____  ___/ /__ _/ /____ ___
#  _/ // _ \(_-</ __/ _ `/ / / / // / _ \/ _  / _ `/ __/ -_|_-<
# /___/_//_/___/\__/\_,_/_/_/  \_,_/ .__/\_,_/\_,_/\__/\__/___/
#                                 /_/
#

sleep 1
clear
install_platform="$(cat ~/.config/ml4w/settings/platform.sh)"
SNAPSHOT_DIR="/home/timeshift/snapshots"
figlet -f smslant "Updates"
echo

# ------------------------------------------------------
# Confirm Start
# ------------------------------------------------------

if gum confirm "DO YOU WANT TO START THE UPDATE NOW?"; then
    echo
    echo ":: Update started."
elif [ $? -eq 130 ]; then
    exit 130
else
    echo
    echo ":: Update canceled."
    exit
fi

_isInstalled() {
    package="$1"
    case $install_platform in
        arch)
            check="$($aur_helper -Qs --color always "${package}" | grep "local" | grep "${package} ")"
            ;;
        fedora)
            check="$(dnf repoquery --quiet --installed ""${package}*"")"
            ;;
        *) ;;
    esac

    if [ -n "${check}" ]; then
        echo 0 #'0' means 'true' in Bash
        return #true
    fi
    echo 1 #'1' means 'false' in Bash
    return #false
}

# Check if platform is supported
case $install_platform in
    arch)
        aur_helper="$(cat ~/.config/ml4w/settings/aur.sh)" # yay.
	aur_helper_flags=""
	
	if gum confirm "DO YOU WANT TO ADD --noconfirm"; then 
	    aur_helper_flags="--noconfirm"
	fi

        if [[ $(_isInstalled "timeshift") == "0" ]]; then
            echo
            if gum confirm "DO YOU WANT TO CREATE A SNAPSHOT?"; then
                echo
                c=$(gum input --placeholder "Enter a comment for the snapshot...")

		sudo timeshift --create --comments "$c"
                echo ":: Snapshot $c created!"
		snapshot_list=$(sudo timeshift --list --scripted 2>/dev/null | rg "^\s*\d+\s+>\s+(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})" -r '$1')
		snapshot_count=$(echo "$snapshot_list" | rg -c "^\d{4}")
		if [ "$snapshot_count" -ge 2 ]; then
		    oldest_snapshot=$(echo "$snapshot_list" | sort | head -n 1 | awk '{print $1}')
		    if [ -n "$oldest_snapshot" ]; then
			echo "Found $snapshot_count snapshots"
			echo "Removing oldest snapshot: $oldest_snapshot"
			sudo timeshift --delete --snapshot "$oldest_snapshot"
			
			if [ $? -eq 0 ]; then
			    echo "Snapshot removed successfully"
			else
			    echo "Error: Failed to remove snapshot"
			fi
		    else
			echo "No snapshots found to remove - check nameing convention"
		    fi
		else
		    echo "Only $snapshot_count snapshot(s) found. Need at least 2 snapshots to remove the oldest."
		fi
		echo "DONE - Snapshots"
                echo
            elif [ $? -eq 130 ]; then
                echo ":: Snapshot skipped."
                exit 130
            else
                echo ":: Snapshot skipped."
            fi
            echo
        fi

	$aur_helper $aur_helper_flags
	hyprpm update # update hyprland plugins
	ya pkg upgrade # upgrade yazi packages

        if [[ $(_isInstalled "flatpak") == "0" ]]; then
            flatpak upgrade -y
        fi
        ;;
    fedora)
        sudo dnf upgrade
        if [[ $(_isInstalled "flatpak") == "0" ]]; then
            flatpak upgrade
        fi
        ;;
    *)
        echo ":: ERROR - Platform not supported"
        echo "Press [ENTER] to close."
        read
        ;;
esac

notify-send "Update complete"
echo
echo ":: Update complete"
echo
echo

echo "Press R to reboot the system, or [Enter] to close..."
read -n 1 -r input

sudo -v
echo -e "Rebooting system..."
reboot

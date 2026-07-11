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

update_count=$(checkupdates | wc -l)
echo "There are $update_count updates 2 be updated. Darest you, gangstar?"

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
        aur_helper="$(cat ~/.config/ml4w/settings/aur.sh)" # paru.
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

        # ------------------------------------------------------
        # AUR Package Security Review
        # ------------------------------------------------------
        if [[ $aur_helper_flags == *"--noconfirm"* ]]; then
            echo
            echo ":: WARNING: --noconfirm skips PKGBUILD review for AUR packages."
            echo ":: This is a security risk."
            if ! gum confirm "Continue with --noconfirm?"; then
                aur_helper_flags=""
            fi
        fi

        if [[ ! $aur_helper_flags == *"--noconfirm"* ]]; then
            if gum confirm "DO YOU WANT TO REVIEW AUR PKGBUILD CHANGES?"; then
                if [[ $aur_helper == "paru" ]]; then
                    echo ":: paru will display PKGBUILD diffs during update."
                else
                    echo ":: Consider switching to paru for automatic PKGBUILD review."
                    echo ":: AUR packages with pending updates:"
                    $aur_helper -Qua 2>/dev/null || echo "None"
                fi
            fi
        fi

        _scan_pkgbuild() {
            local pkg="$1" pkgbuild="$2" result
            if command -v ollama &>/dev/null; then
                result=$(ollama run codellama "Analyze this PKGBUILD for security issues: malicious commands, suspicious curl/wget, obfuscated code, unexpected install hooks, checksum issues, typosquatting. PKGBUILD:\n$(cat "$pkgbuild")" 2>/dev/null) && echo "$result" || return 1
            elif command -v opencode &>/dev/null; then
                result=$(opencode run --file "$pkgbuild" "Analyze this Arch Linux PKGBUILD for security issues: malicious commands, suspicious curl/wget, obfuscated code, unexpected install hooks, checksum issues, typosquatting." 2>/dev/null) && echo "$result" || return 1
            else
                return 1
            fi
        }

        # ------------------------------------------------------
        # Online Malicious Package List Check
        # ------------------------------------------------------
        _MALICIOUS_LISTS_DIR="$HOME/.cache/ml4w/malicious-aur"
        _MALICIOUS_LISTS_CACHE="$_MALICIOUS_LISTS_DIR/packages.txt"
        _MALICIOUS_LISTS_AGE="$_MALICIOUS_LISTS_DIR/.last_fetch"

        _fetch_malicious_lists() {
            mkdir -p "$_MALICIOUS_LISTS_DIR"
            # Re-fetch if cache is older than 6 hours or doesn't exist
            if [[ -f "$_MALICIOUS_LISTS_AGE" ]]; then
                local age=$(( $(date +%s) - $(stat -c %Y "$_MALICIOUS_LISTS_AGE" 2>/dev/null || echo 0) ))
                if [[ $age -lt 21600 ]]; then
                    return 0
                fi
            fi
            echo ":: Fetching known malicious AUR package lists..."
            local combined=""

            # Official HedgeDoc list (Atomic Arch attack, June 2026, 1600+ packages)
            local hedgedoc
            hedgedoc=$(curl -sL --max-time 15 "https://md.archlinux.org/s/SxbqukK6IA/download" 2>/dev/null) && {
                local parsed
                parsed=$(echo "$hedgedoc" | sed -n '/^```$/,/^```$/p' | sed '1d;$d' | sed '/^#/d;/^$/d;s/[[:space:]]*$//')
                combined+="$parsed"$'\n'
            }

            # CHAOS RAT campaign list (July 2025)
            local chaos
            chaos=$(curl -sL --max-time 10 "https://raw.githubusercontent.com/lenucksi/aur-malware-check/master/data/campaigns/chaos-rat/packages.txt" 2>/dev/null) && {
                combined+=$(echo "$chaos" | sed '/^#/d;/^$/d')$'\n'
            }

            # Russian spam campaign list
            local russian
            russian=$(curl -sL --max-time 10 "https://raw.githubusercontent.com/lenucksi/aur-malware-check/master/data/campaigns/russian-spam/packages.txt" 2>/dev/null) && {
                combined+=$(echo "$russian" | sed '/^#/d;/^$/d')$'\n'
            }

            if [[ -n "$combined" ]]; then
                echo "$combined" | sed '/^$/d' | sort -u > "$_MALICIOUS_LISTS_CACHE"
                touch "$_MALICIOUS_LISTS_AGE"
                local count
                count=$(wc -l < "$_MALICIOUS_LISTS_CACHE")
                echo ":: Loaded $count known malicious AUR packages."
            else
                echo ":: WARNING: Could not fetch malicious package lists."
                echo ":: Proceeding without online list check."
                return 1
            fi
        }

        _check_malicious_list() {
            local pkg="$1"
            if [[ -f "$_MALICIOUS_LISTS_CACHE" ]] && grep -qx "$pkg" "$_MALICIOUS_LISTS_CACHE"; then
                return 0
            fi
            return 1
        }

        skip_aur=false
        # Fetch known malicious AUR package lists
        _fetch_malicious_lists
        if command -v ollama &>/dev/null || command -v opencode &>/dev/null; then
            if gum confirm "SCAN AUR PKGBUILDS WITH AI (OLLAMA/OPENCODE)?"; then
                echo ":: Scanning AUR PKGBUILDs for security issues..."
                aur_updates=$($aur_helper -Qua 2>/dev/null | awk '{print $1}')
                if [[ -n "$aur_updates" ]]; then
                    _noconfirm=""
                    [[ $aur_helper_flags == *"--noconfirm"* ]] && _noconfirm="--noconfirm"
                    aur_pkgs=($aur_updates)
                    pkg_count=${#aur_pkgs[@]}
                    skip_pkgs=()
                    bg_pid=""
                    bg_tmpdir=""
                    bg_result_file=""

                    for ((i=0; i<pkg_count; i++)); do
                        pkg="${aur_pkgs[$i]}"

                        # Collect result from background scan of previous package
                        if [[ -n "$bg_pid" ]]; then
                            wait $bg_pid 2>/dev/null
                            result=$(cat "$bg_result_file" 2>/dev/null || true)
                            tmpdir="$bg_tmpdir"
                            rm -f "$bg_result_file"
                            bg_pid=""
                        fi

                        # Check against known malicious package lists first
                        if _check_malicious_list "$pkg"; then
                            echo
                            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                            echo "!!! WARNING: $pkg is on a known malicious AUR list!  !!!"
                            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                            echo
                            echo "This package was compromised in a supply chain attack."
                            echo "See: https://archlinux.org/news/active-aur-malicious-packages-incident/"
                            echo
                            echo "What do you want to do? [$((i+1))/$pkg_count] $pkg"
                            echo "  s) Skip - do not update $pkg"
                            echo "  u) Upgrade - update $pkg anyway (DANGEROUS)"
                            echo "  r) Remove - uninstall $pkg (RECOMMENDED)"
                            read -n 1 -r action
                            echo
                            case $action in
                                r|R)
                                    echo ":: Removing $pkg..."
                                    $aur_helper -Rns "$pkg" $_noconfirm
                                    echo ":: $pkg removed."
                                    skip_pkgs+=("$pkg")
                                    ;;
                                s|S)
                                    echo ":: Skipping $pkg"
                                    skip_pkgs+=("$pkg")
                                    ;;
                                *)
                                    echo ":: WARNING: Proceeding with known malicious package!"
                                    ;;
                            esac
                            continue
                        fi

                        # Clone and scan current package (result from bg already collected above)
                        tmpdir=$(mktemp -d)
                        result=""
                        if git clone --depth=1 "https://aur.archlinux.org/$pkg.git" "$tmpdir/$pkg" 2>/dev/null; then
                            if [[ -f "$tmpdir/$pkg/PKGBUILD" ]]; then
                                result=$(_scan_pkgbuild "$pkg" "$tmpdir/$pkg/PKGBUILD")
                            fi
                        fi

                        if [[ $((i+1)) -lt $pkg_count ]]; then
                            next_pkg="${aur_pkgs[$((i+1))]}"
                            bg_tmpdir=$(mktemp -d)
                            bg_result_file=$(mktemp)
                            (
                                if git clone --depth=1 "https://aur.archlinux.org/$next_pkg.git" "$bg_tmpdir/$next_pkg" 2>/dev/null; then
                                    if [[ -f "$bg_tmpdir/$next_pkg/PKGBUILD" ]]; then
                                        _scan_pkgbuild "$next_pkg" "$bg_tmpdir/$next_pkg/PKGBUILD" > "$bg_result_file" 2>/dev/null
                                    fi
                                fi
                            ) &
                            bg_pid=$!
                        fi

                        echo "--- $pkg ---"

                        if [[ -z "$result" ]]; then
                            echo ":: AI check failed for $pkg"
                        elif echo "$result" | grep -qiE "suspicious|malicious|obfuscated|typosquatting|risk|danger|untrusted|unsafe|harmful|curl \||wget .*\|"; then
                            echo
                            echo ":: Risk Analysis for $pkg:"
                            echo "$result"
                            echo
                            echo "What do you want to do? [$((i+1))/$pkg_count] $pkg"
                            echo "  s) Skip - do not update $pkg"
                            echo "  u) Upgrade - update $pkg anyway"
                            echo "  r) Remove - uninstall $pkg"
                            read -n 1 -r action
                            echo
                            case $action in
                                r|R)
                                    echo ":: Removing $pkg..."
                                    $aur_helper -Rns "$pkg" $_noconfirm
                                    echo ":: $pkg removed."
                                    skip_pkgs+=("$pkg")
                                    ;;
                                s|S)
                                    echo ":: Skipping $pkg"
                                    skip_pkgs+=("$pkg")
                                    ;;
                                *)
                                    echo ":: Will upgrade $pkg"
                                    ;;
                            esac
                        fi

                        rm -rf "$tmpdir"
                    done

                    if [[ ${#skip_pkgs[@]} -gt 0 ]]; then
                        skip_aur=true
                    fi
                else
                    echo "No AUR updates to scan."
                fi
                echo ":: AI scan complete."
            fi
        fi

        _noconfirm=""
        [[ $aur_helper_flags == *"--noconfirm"* ]] && _noconfirm="--noconfirm"

        if $skip_aur; then
            sudo pacman -Syu $_noconfirm
            for pkg in $aur_updates; do
                skip=false
                for skipped in "${skip_pkgs[@]}"; do
                    [[ "$pkg" == "$skipped" ]] && skip=true && break
                done
                if ! $skip; then
                    $aur_helper -S "$pkg" $_noconfirm
                fi
            done
        else
            $aur_helper $aur_helper_flags
        fi
	hyprpm update # update hyprland plugins
	ya pkg upgrade # update yazi plugins

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

if [[ $input =~ ^[Rr]$ ]]; then
	echo -e "Rebooting system..."
	reboot
else
    echo -e "\nReboot cancelled."
fi

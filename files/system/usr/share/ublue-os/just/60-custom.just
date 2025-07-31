

# vim: set ft=make :
########################
### bluefin-apps.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

# alias for setup-cockpit
[group('Apps')]
cockpit:
    @ujust setup-cockpit

# Enable Cockpit for web-based system management | https://cockpit-project.org/
[group('Apps')]
setup-cockpit ACTION="":
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh

    MANAGED_COCKPIT_CONTAINER="cockpit-ws"

    if sudo podman container exists $MANAGED_COCKPIT_CONTAINER ; then
        COCKPIT_CONTAINER_STATUS_PRETTY="${green}${b}Installed${n}"
        COCKPIT_CONTAINER_STATUS=1
    else
        COCKPIT_CONTAINER_STATUS_PRETTY="${invert}${b}Not installed${n}"
        COCKPIT_CONTAINER_STATUS=0
    fi

    COCKPIT_SERVICE_STATUS="$(systemctl is-enabled cockpit.service)"
    if [ "$COCKPIT_SERVICE_STATUS" == "enabled" ]; then
        COCKPIT_SERVICE_STATUS="${green}${b}Enabled${n}"
    elif [ "$COCKPIT_SERVICE_STATUS" == "disabled" ]; then
        COCKPIT_SERVICE_STATUS="${red}${b}Disabled${n}"
    else
        COCKPIT_SERVICE_STATUS="${invert}${b}Not installed${n}"
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
        cat <<EOF
    Usage: ujust setup-cockpit <option>
      <option>: Specify the quick option to skip the prompt
      Use 'install' to select Install Cockpit
      Use 'enable' to select Enable Cockpit
      Use 'disable' to select Disable Cockpit
      Use 'uninstall' to select Uninstall Cockpit
    EOF
        exit 0
    elif [ "$OPTION" == "" ]; then
        echo "${bold}Cockpit Setup${normal}"
        echo "Cockpit service is currently: $COCKPIT_SERVICE_STATUS"
        echo "The Cockpit container is currently: $COCKPIT_CONTAINER_STATUS_PRETTY"
        if [[ "${COCKPIT_CONTAINER_STATUS}" -eq 0 ]]; then
            echo "Warning: This will enable ssh password login because Cockpit requires it."
            OPTION=$(Choose "Install Cockpit" "Cancel")
        else
            OPTION=$(Choose "Enable Cockpit" "Disable Cockpit" "Uninstall Cockpit")
        fi
    fi
    if [[ "${OPTION,,}" =~ ^install ]]; then
        echo "${blue}${b}Installing Cockpit${n}"
        sudo /bin/bash <<EOF
    [ ! -f /etc/ssh/sshd_config.d/02-enable-passwords.conf ] && echo -e "# File managed by ujust cockpit\nPasswordAuthentication yes" > /etc/ssh/sshd_config.d/02-enable-passwords.conf
    systemctl -q try-restart sshd
    systemctl -q enable --now sshd
    if ! podman image exists quay.io/cockpit/ws ; then
        podman pull quay.io/cockpit/ws:latest
    fi
    podman container runlabel -q --name $MANAGED_COCKPIT_CONTAINER RUN quay.io/cockpit/ws
    podman container runlabel -q INSTALL quay.io/cockpit/ws systemctl enable cockpit.service
    EOF
        OPTION="Enable Cockpit"
    fi
    if [[ "${OPTION,,}" =~ ^enable ]]; then
        sudo /bin/bash <<EOF
    echo "${green}${b}Enabling${n} Cockpit"
    systemctl -q enable --now cockpit.service
    podman start $MANAGED_COCKPIT_CONTAINER
    echo "$(Urllink "http://localhost:9090" "Open Cockpit${n}") -> http://localhost:9090"
    EOF
    fi
    if [[ "${OPTION,,}" =~ ^disable ]]; then
        echo "${red}${b}Disabling${n} Cockpit"
        sudo /bin/bash <<EOF
    systemctl -q disable cockpit.service
    podman stop $MANAGED_COCKPIT_CONTAINER
    EOF
        echo "Cockpit has been ${b}${red}disabled${n}"
    fi
    if [[ "${OPTION,,}" =~ ^uninstall ]] ; then
        sudo /bin/bash <<EOF
    [ -f /etc/ssh/sshd_config.d/02-enable-passwords.conf ] && rm -f /etc/ssh/sshd_config.d/02-enable-passwords.conf
    systemctl -q try-restart sshd
    systemctl -q disable --now cockpit.service
    rm -f /etc/systemd/system/cockpit.service
    podman stop -i $MANAGED_COCKPIT_CONTAINER
    podman rm -f $MANAGED_COCKPIT_CONTAINER
    EOF
        echo "Cockpit has been ${red}${b}uninstalled${n}"
    fi

# alias for install-jetbrains-toolbox
[group('Apps')]
jetbrains-toolbox:
    @ujust install-jetbrains-toolbox

# Install JetBrains Toolbox | https://www.jetbrains.com/toolbox-app/
[group('Apps')]
install-jetbrains-toolbox:
    #!/usr/bin/env bash
    pushd "$(mktemp -d)"
    echo "Get latest JetBrains Toolbox version"
    # Get the json with latest releases
    curl -sSfL -o releases.json "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"
    # Extract information
    BUILD_VERSION=$(jq -r '.TBA[0].build' ./releases.json)
    DOWNLOAD_LINK=$(jq -r '.TBA[0].downloads.linux.link' ./releases.json)
    CHECKSUM_LINK=$(jq -r '.TBA[0].downloads.linux.checksumLink' ./releases.json)
    echo "Installing JetBrains Toolbox ${BUILD_VERSION}"
    curl -sSfL -O "${DOWNLOAD_LINK}"
    curl -sSfL "${CHECKSUM_LINK}" | sha256sum -c
    tar zxf jetbrains-toolbox-"${BUILD_VERSION}".tar.gz
    mkdir -p $HOME/.local/share/JetBrains/ToolboxApp/
    mv jetbrains-toolbox-"${BUILD_VERSION}"/* $HOME/.local/share/JetBrains/ToolboxApp/
    echo "Launching JetBrains Toolbox"
    $HOME/.local/share/JetBrains/ToolboxApp/bin/jetbrains-toolbox

# alias for install-incus
[group('Apps')]
incus:
    @ujust install-incus

# Install OpenTabletDriver, an open source, cross-platform, user-mode tablet driver
[group('Apps')]
install-opentabletdriver:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    echo "Installer for OpenTabletDriver..."
    echo "${bold}Install or Remove OpenTabletDriver${normal}"
    OPTION=$(Choose "Install" "Uninstall" "Exit")
    if [[ "${OPTION,,}" =~ ^install ]]; then
        echo "Installing OpenTabletDriver..."
        curl -s https://api.github.com/repos/OpenTabletDriver/OpenTabletDriver/releases/latest \
        | jq -r '.assets | sort_by(.created_at) | .[] | select (.name|test("opentabletdriver.*tar.gz$")) | .browser_download_url' \
        | wget -qi - -O /tmp/OpenTabletDriver/opentabletdriver.tar.gz && \
        tar --strip-components=1 -xvzf /tmp/OpenTabletDriver/opentabletdriver.tar.gz -C /tmp/OpenTabletDriver && \
        pkexec cp /tmp/OpenTabletDriver/etc/udev/rules.d/70-opentabletdriver.rules /etc/udev/rules.d/71-opentabletdriver.rules && \
        rm -rf /tmp/OpenTabletDriver && \
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo && \
        flatpak --system install -y flathub net.opentabletdriver.OpenTabletDriver && \
        mkdir -p $HOME/.config/OpenTabletDriver && \
        flatpak override --user --filesystem=xdg-config/OpenTabletDriver net.opentabletdriver.OpenTabletDriver && \
        mkdir -p $HOME/.config/systemd/user && \
        curl -s https://raw.githubusercontent.com/flathub/net.opentabletdriver.OpenTabletDriver/refs/heads/master/scripts/opentabletdriver.service > $HOME/.config/systemd/user/opentabletdriver.service  && \
        systemctl --user daemon-reload && \
        systemctl enable --user --now opentabletdriver.service
    elif [[ "${OPTION,,}" =~ ^uninstall ]]; then
        echo "Uninstalling OpenTabletDriver..."
        pkexec rm /etc/udev/rules.d/71-opentabletdriver.rules && \
        flatpak --system remove -y flathub net.opentabletdriver.OpenTabletDriver
    else
        echo "Have a good day :)!"
    fi

# Install and configure Incus
[group('Apps')]
install-incus:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if ! grep -e "-dx" <<< $CURRENT_IMAGE ; then
        echo "Developer mode is currently ${b}${red}Disabled${n}."
        echo "Run \"ujust devmode\" to turn on Developer mode."
        exit
    fi
    echo 'Installing and configuring Incus.'
    /usr/libexec/bluefin-incus

# Install Kubernetes CLI dev tools
[group('Apps')]
install-k8s-dev-tools:
    #!/usr/bin/bash
    echo "Adding Kubernetes command line tools..."
    brew bundle --file /usr/share/ublue-os/homebrew/kubernetes.Brewfile

# Set up command-not-found for Homebrew
[group('Apps')]
setup-brew-not-found ACTION="":
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh

    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
        echo "Usage: ujust setup-brew-not-found <option>"
        echo "  <option>: Specify the quick option to skip the prompt"
        echo "  Use 'enable' to select Enable Brew Not Found"
        echo "  Use 'disable' to select Disable Brew Not Found"
        exit 0
    elif [ "$OPTION" == "" ]; then
        echo "${bold}Brew command-not-found Setup${normal}"
        OPTION=$(Choose "Enable Brew command-not-found" "Disable Brew command-not-found")
    fi

    set -euo pipefail

    BREW_BINARY=/home/linuxbrew/.linuxbrew/bin/brew
    HOMEBREW_REPOSITORY=${HOMEBREW_REPOSITORY:-$($BREW_BINARY --repository)}
    if ! $BREW_BINARY -h > /dev/null; then
      echo "Make sure Homebrew is installed first. Check journalctl -e -u brew-setup.service"
      exit
    fi

    if [[ "${OPTION,,}" =~ ^enable ]]; then
        $BREW_BINARY tap homebrew/command-not-found
        pkexec tee /etc/profile.d/brew-command-not-found.sh > /dev/null <<EOF
    # Check for interactive bash or zsh and that we haven't already been sourced
    if [[ -d /home/linuxbrew/.linuxbrew && \$- == *i* && BREW_COMMAND_NOT_FOUND != 1 ]] ; then
      HB_CNF_HANDLER="${HOMEBREW_REPOSITORY}/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
      [ -f "\$HB_CNF_HANDLER" ] && source "\$HB_CNF_HANDLER"
      export BREW_COMMAND_NOT_FOUND=1
    fi
    EOF
        # Necessary for fish since just having a script sourcing it does not work
        pkexec ln -sf "${HOMEBREW_REPOSITORY}/Library/Taps/homebrew/homebrew-command-not-found/handler.fish" /etc/fish/conf.d/brew-cnf-handler.fish
        echo "Brew command-not-found has been ${b}${green}enabled${n}"
    fi

    if [[ "${OPTION,,}" =~ ^disable ]]; then
        $BREW_BINARY untap homebrew/command-not-found
        FILES_TO_BE_REMOVED=()
        [ -f /etc/profile.d/brew-command-not-found.sh ] && FILES_TO_BE_REMOVED+=("/etc/profile.d/brew-command-not-found.sh")
        [ -f /etc/fish/conf.d/brew-command-not-found.fish ] && FILES_TO_BE_REMOVED+=("/etc/fish/conf.d/brew-command-not-found.fish")
        pkexec rm -f "${FILES_TO_BE_REMOVED[@]}"
      echo "Brew command-not-found has been ${b}${red}disabled${n}"
    fi

# Install gaming flatpaks

# 23.08 runtime versions are needed for Heroic/Lutris
[group('Apps')]
install-gaming-flatpaks:
    #!/usr/bin/env bash
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak --system -y install --or-update app/com.valvesoftware.Steam/x86_64/stable \
                                            app/com.heroicgameslauncher.hgl/x86_64/stable \
                                            app/net.lutris.Lutris/x86_64/stable \
                                            app/com.vysp3r.ProtonPlus/x86_64/stable \
                                            app/com.dec05eba.gpu_screen_recorder/x86_64/stable \
                                            app/com.github.Matoking.protontricks/x86_64/stable \
                                            runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08 \
                                            runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08 \
                                            runtime/org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/24.08 \
                                            runtime/com.obsproject.Studio.Plugin.OBSVkCapture/x86_64/stable \
                                            runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08 \
                                            runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08 \
                                            runtime/com.valvesoftware.Steam.Utility.steamtinkerlaunch/x86_64/stable


# vim: set ft=make :
########################
### bluefin-system.just
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

# Run a one minute system benchmark
[group('System')]
benchmark:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    if ! type -P "stress-ng" &>/dev/null ; then
        if gum confirm "Stress does not seem to be on your path, do you wish to install it?" ; then
            set -eu
            brew install stress-ng
            brew link stress-ng
            set +eu
        else
            exit 0
        fi
    fi

    echo 'Running a 1 minute benchmark ...'
    trap popd EXIT
    pushd $(mktemp -d)
    stress-ng --matrix 0 -t 1m --times

# Configure Bluefin-CLI Terminal Experience with Brew
[group('System')]
bluefin-cli:
    @/usr/libexec/ublue-bling

# alias for toggle-devmode
devmode:
    @ujust toggle-devmode

# Toggle between Bluefin and the Developer Experience
[group('System')]
toggle-devmode:
    #!/usr/bin/env bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if grep -q "/var/ublue-os/image" <<< $CURRENT_IMAGE ; then
        bash -c "cat <<EOF
    Before we can switch to the Bluefin Developer Experience
    the current system needs an update. Please run 'ujust update'
    and reboot your system when the update is finished
    EOF"
        exit
    fi
    if /bin/grep -q "\-dx" <<< $CURRENT_IMAGE ; then
        CURRENT_STATE="enabled"
    else
        CURRENT_STATE="disabled"
    fi
    echo "Developer mode is currently ${CURRENT_STATE}"
    echo "Enable or Disable developer mode"
    OPTION=$(Choose Enable Disable)
    if [[ "${OPTION,,}" =~ ^enable ]]; then
        if [ "$CURRENT_STATE" = "enabled" ] ; then
            echo "You are already on a developer image"
            exit 0
        fi
        echo "Rebasing to a developer image"
        NEW_IMAGE=$(sed "s/bluefin/bluefin-dx/" <<< $CURRENT_IMAGE)
        rpm-ostree rebase $NEW_IMAGE
        echo -e "\nUse `ujust dx-group` to add your user to the correct groups and complete the installation"
    fi
    if [[ "${OPTION,,}" =~ ^disable ]]; then
        if [ "$CURRENT_STATE" != "enabled" ]; then
            echo "You are currently not on a developer image"
            exit 0
        fi
        echo "Rebasing to a non developer image"
        # Remove -dx suffix from image, specifies ":" to mark the end of the image name
        NEW_IMAGE=$(sed "s/\-dx//" <<< $CURRENT_IMAGE)
        rpm-ostree rebase $NEW_IMAGE
    fi
    if gum choose "Do you want to also install the default development flatpaks?" ; then
        ujust install-system-flatpaks 1
    fi

# Ptyxis terminal transparency
[group('System')]
ptyxis-transparency opacity="0.95":
    #!/usr/bin/env bash
    set -euxo pipefail
    if [[ -n "$(echo "{{ opacity }}" | grep -v '^[.0-9]*$')" ]]; then
        printf "Value must be numeric: %s.\n" "{{ opacity }}"
    elif [[ $(echo "0<{{ opacity }} && 1>={{ opacity }}" | bc -q) -eq 1 ]]; then
        raw="$(/usr/bin/gsettings get org.gnome.Ptyxis profile-uuids)"
        uuids="$(sed -En 's|[^0-9a-z]*||g; s|([0-9a-z]{32})|\1\n|gp' <<<${raw})"
        for i in ${uuids}; do
            location="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${i}/"
            /usr/bin/gsettings set "${location}" opacity "{{ opacity }}"; done
        printf "Ptyxis opacity is now %s.\n" "{{ opacity }}"
    else
        printf "Value must be greater than 0 and less than or equal to 1: %s.\n" "{{ opacity }}"
    fi

# Configure docker,incus-admin,libvirt, container manager, serial permissions
[group('System')]
dx-group:
    #!/usr/bin/pkexec bash
    append_group() {
        local group_name="$1"
        if ! grep -q "^$group_name:" /etc/group; then
            echo "Appending $group_name to /etc/group"
            grep "^$group_name:" /usr/lib/group | sudo tee -a /etc/group > /dev/null
        fi
    }

    GROUPS_ADD=("docker" "incus-admin" "libvirt" "dialout")

    for GROUP_ADD in "${GROUPS_ADD[@]}" ; do
        append_group $GROUP_ADD
        usermod -aG $GROUP_ADD {{ `id -un` }}
    done

    echo "Reboot system and log back in to use docker, libvirt, incus, and serial connections."

# alias for configure-vfio
[group('System')]
setup-vfio:
    @ujust configure-vfio

# Configure system to use vfio and kvmfr
[group('System')]
configure-vfio ACTION="":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_IMAGE=$(rpm-ostree status -b --json | jq -r '.deployments[0]."container-image-reference"')
    if grep -q "dx" <<< $CURRENT_IMAGE ; then
        DEVMODE="enabled"
    else
        DEVMODE="disabled"
    fi
    if [ "$DEVMODE" == "disabled" ]; then
        echo "Please run "ujust devmode" first"
        exit 0
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "help" ]; then
        bash -c "cat <<EOF
    Usage: ujust configure-vfio <option>
      <option>: Specify the quick option to skip the prompt
      Use 'vfio-on' to select Enable VFIO drivers
      Use 'vfio-off' to select Disable VFIO drivers
      Use 'kvmfr' to enable kvmfr module for looking-glass
    EOF"
        exit 0
    elif [ "$OPTION" == "" ]; then
        bash -c "cat <<EOF
    ${bold}VFIO and kvmfr Configuration${normal}
    This is only used for GPU passthrough of a secondary dGPU.
    It will enable vfio and configure kvmfr for use with $(Urllink "https://looking-glass.io" "Looking Glass").
    If you do not plan to use any of this then press ESC.
    ${bold}NOTE:${normal} Since this is a niche use case, support will be ${b}very limited${n}
    EOF"
        OPTION=$(Choose \
          "Enable VFIO drivers" \
          "Disable VFIO drivers" \
          "Enable kvmfr module" \
        )
    fi
    if [[ "${OPTION,,}" =~ (^enable[[:space:]]vfio|vfio-on) ]]; then
        echo "Enabling VFIO..."
        CPU_VENDOR=$(grep "vendor_id" "/proc/cpuinfo" | uniq | awk -F": " '{ print $2 }')
        VENDOR_KARG="unset"
        if [[ ${CPU_VENDOR} == "AuthenticAMD" ]]; then
            VENDOR_KARG="amd_iommu=on"
        elif [[ ${CPU_VENDOR} == "GenuineIntel" ]]; then
            VENDOR_KARG="intel_iommu=on"
        fi
        if [[ ${VENDOR_KARG} == "unset" ]]; then
            echo "Failed to get CPU vendor, exiting..."
            exit 1
        else
            rpm-ostree kargs \
                --append-if-missing="${VENDOR_KARG}" \
                --append-if-missing="iommu=pt" \
                --append-if-missing="rd.driver.pre=vfio_pci" \
                --append-if-missing="vfio_pci.disable_vga=1" \
                --append-if-missing="kvm.ignore_msrs=1" \
                --append-if-missing="kvm.report_ignored_msrs=0"
            if sudo test ! -f "/etc/libvirt/hooks/qemu"; then
                echo "Adding libvirt qemu hooks"
                sudo wget 'https://raw.githubusercontent.com/PassthroughPOST/VFIO-Tools/master/libvirt_hooks/qemu' -O /etc/libvirt/hooks/qemu
                sudo chmod +x /etc/libvirt/hooks/qemu
                sudo grep -A1 -B1 "# Add" /etc/libvirt/hooks/qemu | sed 's/^# //g'
                echo ""
                if sudo test ! -d "/etc/libvirt/hooks/qemu.d"; then
                    sudo mkdir /etc/libvirt/hooks/qemu.d
                fi
            fi
            echo "VFIO will be enabled on next boot, make sure you enable IOMMU, VT-d or AMD-v in your BIOS!"
            echo "Please understand that since this is such a niche use case, support will be very limited!"
            echo "To add your unused/second GPU device ids to the vfio driver by running"
            echo 'rpm-ostree kargs --append-if-missing="vfio-pci.ids=xxxx:yyyy,xxxx:yyzz"'
            echo 'you can find these using "ls-iommu -gr" or "ls-iommu -grr"'
            echo 'for a dedicated gpu there will be at least 1 vga device and 1 audio device.'
            echo "NOTE: The GPU you bound to vfio-pci will not be usable by the host after you do this!"
        fi
    elif [[ "${OPTION,,}" =~ (^disable[[:space:]]vfio|vfio-off) ]]; then
        echo ""
        echo "Make sure you have ${b}disabled autostart of all VMs using VFIO${n} before continuing!"
        CONFIRM=$(Choose Cancel Continue)
        if [ "$CONFIRM" == "Continue" ]; then
            echo "Disabling VFIO..."
            VFIO_IDS="$(rpm-ostree kargs | sed -E 's/.+(vfio_pci.ids=.+\s)/\1/' | awk '{ print $1 }' | grep vfio_pci.ids)"
            VFIO_IDS_KARG=""
            if [ -n "$VFIO_IDS" ]; then
                echo "Found VFIO ids in kargs, adding the below line to removal list"
                echo "$VFIO_IDS"
                VFIO_IDS_KARG="--delete-if-present=\"$VFIO_IDS\""
            fi
            rpm-ostree kargs \
                --delete-if-present="iommu=pt" \
                --delete-if-present="iommu=on" \
                --delete-if-present="amd_iommu=on" \
                --delete-if-present="intel_iommu=on" \
                --delete-if-present="rd.driver.pre=vfio_pci" \
                --delete-if-present="vfio_pci.disable_vga=1" \
                --delete-if-present="vfio_pci.disable_vga=0" \
            $VFIO_IDS_KARG
        fi
    elif [[ "${OPTION,,}" =~ kvmfr ]]; then
        sudo /usr/libexec/bluefin-dx-kvmfr-setup
    fi

# Install system flatpaks for rebasers
[group('System')]
install-system-flatpaks $dx="dynamic":
    #!/usr/bin/bash
    TARGET_FLATPAK_FILE="${TARGET_FLATPAK_FILE:-/etc/ublue-os/system-flatpaks.list}"
    TARGET_DEVMODE_FILE="${TARGET_DEVMODE_FILE:-/etc/ublue-os/system-flatpaks-dx.list}"
    case "$dx" in
        "0"|"1")
            ADD_DEVMODE="$dx"
            ;;
        "dynamic")
            if [[ $(jq '."image-flavor"' /usr/share/ublue-os/image-info.json) =~ dx ]] ; then
                ADD_DEVMODE=1
            fi
            ;;
        *)
            echo "Unsupported option"
            exit 1
            ;;
    esac

    flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
    xargs flatpak --system -y install --or-update < $TARGET_FLATPAK_FILE
    if [ "$ADD_DEVMODE" == "1" ] ; then
        xargs flatpak --system -y install --or-update < $TARGET_DEVMODE_FILE
    fi

# Configure grub bootmenu visibility
[group('System')]
configure-grub:
    @/usr/libexec/configure-grub.sh

alias switch-stream := rebase-helper
alias switch-streams := rebase-helper
alias rollback-helper := rebase-helper

# Rebase assistant
[group('System')]
rebase-helper:
    @/usr/bin/ublue-rollback-helper

# Toggle tailscale
[group('System')]
toggle-tailscale:
    #!/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh
    source /usr/lib/os-release

    TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"

    if [ "$TAILSCALED_STATUS" == "enabled" ] || [ "$TAILSCALED_STATUS" == "disabled" ]; then
        TAILSCALED="Installed"
    else
        TAILSCALED="Not Found"
        echo "${b}${red}Unable to enable or disable Tailscale.${n}"
        echo "The tailscaled service must be present and either enabled or disabled to run this script."
        echo "tailscaled service status: $TAILSCALED_STATUS"
    fi


    if [ "$TAILSCALED" == "Installed" ]; then
        echo "Enable or disable Tailscale?"
        TS_OPTION=$(Choose Enable Disable)

        # gnome-extensions is only available on Bluefin (Gnome)
        if [ "$VARIANT" == "Silverblue" ]; then
            TAILSCALE_QS="$(gnome-extensions list | grep -q "tailscale@joaophi.github.com"; echo $?)"
            if [ "$TAILSCALE_QS" == 0 ]; then
                TAILSCALE_QS="Installed"
            else
                echo "The Tailscale QS extension for Gnome is not installed. Please install it and then run this script again."
            fi

            if [[ "${TS_OPTION,,}" =~ ^enable ]]; then
                gnome-extensions enable tailscale@joaophi.github.com
            elif [[ "${TS_OPTION,,}" =~ ^disable ]]; then
                gnome-extensions disable tailscale@joaophi.github.com
            fi
        fi

        if [ "$TS_OPTION" = "Enable" ]; then
            systemctl enable --now tailscaled
            TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"
            if [ "$TAILSCALED_STATUS" == "enabled" ]; then
                echo "${b}${green}Tailscale is enabled.${n}"
                echo "If this is your first time using Tailscale, setup is necessary."
                echo "Refer to Tailscale's documentation at https://tailscale.com/kb/1346/start."
            fi
        elif [ "$TS_OPTION" = "Disable" ]; then
            systemctl disable --now tailscaled
            TAILSCALED_STATUS="$(systemctl is-enabled tailscaled || true )"
            if [ "$TAILSCALED_STATUS" == "disabled" ]; then
                echo "${b}${red}Tailscale is disabled.${n}"
            fi
        fi
    fi

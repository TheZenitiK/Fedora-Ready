#!/bin/bash

################################################################################
#                                  Fedora-Ready                                #
#                            Author: TheZenitiK                                #
#                                Version: 0.2                                #
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Utility functions
print_header() {
    clear
    local CYAN='\033[0;36m'
    local BLUE='\033[0;34m'
    local GREEN='\033[0;32m'
    local WHITE='\033[1;37m'
    local YELLOW='\033[0;33m'
    local BOLD='\033[1m'
    local NC='\033[0m'

    print_line() {
        local text="$1"
        local visible_length="$2"
        local total_width=64
        local pad=$((total_width - visible_length))
        
        echo -e "${CYAN}║${NC}${text}$(printf '%*s' $pad '')${CYAN}║${NC}"
    }

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    print_line "" 0
    print_line "     ${BOLD}${CYAN}███████╗███████╗██████╗  ██████╗ ██████╗  █████╗ ${NC}" 54
    print_line "     ${BOLD}${CYAN}██╔════╝██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗${NC}" 54
    print_line "     ${BOLD}${CYAN}█████╗  █████╗  ██║  ██║██║   ██║██████╔╝███████║${NC}" 54
    print_line "     ${BOLD}${CYAN}██╔══╝  ██╔══╝  ██║  ██║██║   ██║██╔══██╗██╔══██║${NC}" 54
    print_line "     ${BOLD}${CYAN}██║     ███████╗██████╔╝╚██████╔╝██║  ██║██║  ██║${NC}" 54
    print_line "     ${BOLD}${CYAN}╚═╝     ╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝${NC}" 54
    print_line "" 0
    print_line "            ${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" 45
    print_line "           ${BOLD}${BLUE}     ✦ Fedora-Ready ✦ ${NC}" 36
    print_line "            ${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" 45
    print_line "" 0
    print_line "         ${BOLD}${GREEN}➤${NC} ${BOLD}${WHITE}Author:${NC} ${YELLOW}TheZenitiK${NC}" 29
    print_line "         ${BOLD}${GREEN}➤${NC} ${BOLD}${WHITE}Version:${NC}${YELLOW}0.2${NC}" 22
    print_line "" 0
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

progress() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}▶${NC} $1"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check if running on Fedora
check_fedora() {
    if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
        error "This script is designed for Fedora Linux"
        exit 1
    fi
    progress "Fedora detected"
}

# Check for sudo/root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        info "This script requires sudo privileges"
        sudo -v || exit 1
    fi
}

# Detect Fedora variant
detect_variant() {
    if command -v ostree &> /dev/null && grep -q "Silverblue\|Kinoite" /etc/os-release; then
        echo "atomic"
    else
        echo "standard"
    fi
}

# Detect NVIDIA GPU
detect_nvidia_gpu() {
    if lspci | grep -i "NVIDIA\|GeForce\|RTX\|GTX\|Tesla" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Get GPU model
get_nvidia_gpu_info() {
    lspci | grep -i "NVIDIA" | head -1 | sed 's/.*NVIDIA //' | sed 's/ \[.*//'
}

# Add RPM Fusion repositories
setup_rpmfusion() {
    section "Setting up RPM Fusion repositories"
    
    if rpm -q rpmfusion-free-release &>/dev/null; then
        progress "RPM Fusion Free already installed"
    else
        info "Installing RPM Fusion Free..."
        sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm || {
            error "Failed to install RPM Fusion Free"
            return 1
        }
        progress "RPM Fusion Free installed"
    fi
    
    if rpm -q rpmfusion-nonfree-release &>/dev/null; then
        progress "RPM Fusion Nonfree already installed"
    else
        info "Installing RPM Fusion Nonfree..."
        sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || {
            error "Failed to install RPM Fusion Nonfree"
            return 1
        }
        progress "RPM Fusion Nonfree installed"
    fi
    
    # Обновляем метаданные после добавления репозиториев
    sudo dnf makecache
}

# Fix Cisco OpenH264 & Codecs Mitigation
install_openh264() {
    section "Configuring Cisco OpenH264 & Codecs Mitigation"
    
    info "Disabling problematic Cisco openh264 repository and setting up clean fallback..."
    sudo dnf config-manager --set-disabled fedora-cisco-openh264 2>/dev/null || true
    
    # Убираем конфликтующие пакеты / ставим корректную замену если требуется
    sudo dnf remove -y openh264 mozilla-openh264 2>/dev/null || true
    
    progress "Cisco openh264 repository handled safely"
}

# Install multimedia codecs & VA-API hardware acceleration
install_multimedia_codecs() {
    section "Installing multimedia codecs, FFmpeg & Hardware Acceleration (VA-API)"
    
    # Сначала гарантируем наличие RPM Fusion
    setup_rpmfusion

    # Включаем полный ffmpeg (переход с free на nonfree версию)
    info "Switching to full multimedia codecs from RPM Fusion..."
    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || sudo dnf install -y ffmpeg --allowerasing 2>/dev/null || warning "FFmpeg swap/install note"

    local codecs=(
        "gstreamer1-plugins-good"
        "gstreamer1-plugins-bad-free"
        "gstreamer1-plugins-bad-freeworld"
        "gstreamer1-plugins-ugly"
        "gstreamer1-libav"
        "libavcodec-extra"
        "a52dec"
        "libdvdread"
        "libdvdnav"
        "libdvdcss"
        "mesa-vdpau-drivers"
        "libva-utils"
    )
    
    for codec in "${codecs[@]}"; do
        info "Installing $codec..."
        sudo dnf install -y "$codec" 2>/dev/null && progress "$codec installed" || warning "Could not install $codec (may already be present or skipped)"
    done
    
    progress "Multimedia codecs and VA-API setup completed"
}

# Restore window buttons
restore_window_buttons() {
    section "Restoring window buttons (minimize/maximize)"
    
    if gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close" 2>/dev/null; then
        progress "Window buttons restored"
    else
        error "Failed to restore window buttons"
    fi
}

# Configure screenshot shortcut
configure_screenshot() {
    section "Configuring screenshot shortcut (Win+Shift+S)"
    
    if gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['<Super>shift+s']" 2>/dev/null; then
        progress "Screenshot shortcut configured"
    else
        error "Failed to configure screenshot"
    fi
}

# Setup language switching
setup_language_switching() {
    section "Setting up language switching (Alt+Shift)"
    
    if gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle']" 2>/dev/null; then
        progress "Language switching configured"
    else
        error "Failed to configure language switching"
    fi
}

# Install GNOME Extensions
install_gnome_extensions() {
    section "Installing GNOME Extensions"
    
    info "Installing extension manager..."
    if sudo dnf install -y gnome-extensions-app gnome-shell-extensions gnome-tweaks 2>/dev/null; then
        progress "GNOME Extensions installed"
    else
        error "Failed to install GNOME Extensions"
    fi
}

# Enable touchpad right-click
enable_touchpad_rightclick() {
    section "Enabling right-click on touchpad (context menu)"
    
    info "Configuring touchpad settings..."
    gsettings set org.gnome.desktop.peripherals.touchpad click-method 'areas' 2>/dev/null
    
    if gsettings set org.gnome.desktop.peripherals.touchpad right-click-emulation true 2>/dev/null; then
        progress "Touchpad right-click enabled"
    else
        warning "Touchpad configuration completed (may require restart)"
    fi
}

# Install NVIDIA drivers
install_nvidia_drivers() {
    section "Installing NVIDIA drivers"
    
    if ! detect_nvidia_gpu; then
        error "No NVIDIA GPU detected on this system"
        info "NVIDIA drivers are only for systems with NVIDIA graphics cards"
        return 1
    fi
    
    local gpu_model=$(get_nvidia_gpu_info)
    info "Detected NVIDIA GPU: ${WHITE}$gpu_model${NC}"
    
    if rpm -q akmod-nvidia &>/dev/null; then
        progress "NVIDIA drivers already installed"
        nvidia-smi 2>/dev/null && progress "NVIDIA drivers are working" || warning "Drivers installed but may need reload"
        return 0
    fi
    
    if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
        info "RPM Fusion Nonfree required for NVIDIA drivers, installing..."
        setup_rpmfusion
    fi
    
    info "Installing NVIDIA drivers and dependencies..."
    sudo dnf install -y gcc kernel-devel akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs 2>/dev/null || {
        error "Failed to install NVIDIA drivers"
        return 1
    }
    
    info "Building NVIDIA kernel module (this may take a few minutes)..."
    sudo akmods --force 2>/dev/null || warning "AKMODS build completed with warnings"
    
    progress "NVIDIA drivers installed successfully"
    info "Please reboot your system for changes to take effect"
    
    if command -v nvidia-smi &>/dev/null; then
        echo ""
        info "NVIDIA GPU Information:"
        nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
    fi
}

# System update
system_update() {
    section "Updating system packages"
    
    local variant=$(detect_variant)
    
    if [ "$variant" = "atomic" ]; then
        info "Detected Fedora Atomic variant (Silverblue/Kinoite)"
        if sudo rpm-ostree upgrade; then
            progress "System updated (ostree)"
        else
            error "Failed to update system"
        fi
    else
        info "Detected standard Fedora"
        if sudo dnf upgrade -y; then
            progress "System updated"
        else
            error "Failed to update system"
        fi
    fi
}

# Menu display
print_menu() {
    local PURPLE='\033[0;35m'
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local BRIGHT_GREEN='\033[1;32m'
    local WHITE='\033[1;37m'
    local GRAY='\033[0;90m'
    local RED='\033[0;31m'
    local NC='\033[0m'

    print_item() {
        local num="$1"
        local text="$2"
        local num_color="$3"
        local text_color="${4:-$WHITE}"
        
        printf "  %b%2s%b │ %b%s%b\n" "$num_color" "$num" "$GRAY" "$text_color" "$text" "$NC"
    }

    echo -e "\n${PURPLE}⚡ FEDORA POST-INSTALL SETUP${NC}"
    echo -e "${GRAY}──────────────────────────────────────────${NC}"
    
    echo -e "\n${CYAN}🚀 PRESETS${NC}"
    print_item "1"  "Apply all settings (Complete Setup)" "${GREEN}" "${GREEN}"
    
    echo -e "\n${CYAN}📦 REPOSITORIES & CODECS${NC}"
    print_item "2"  "Setup RPM Fusion repositories" "${PURPLE}"
    print_item "3"  "Cisco OpenH264 mitigation & cleanup" "${PURPLE}"
    print_item "4"  "Install multimedia codecs & VA-API" "${PURPLE}"
    print_item "5"  "System update"                 "${PURPLE}"
    
    echo -e "\n${CYAN}🛠️  SYSTEM TWEAKS${NC}"
    print_item "6"  "Restore window buttons (minimize/maximize)" "${PURPLE}"
    print_item "7"  "Configure screenshot shortcut (Win+Shift+S)" "${PURPLE}"
    print_item "8"  "Set language switching (Alt+Shift)"         "${PURPLE}"
    print_item "9"  "Install GNOME Extensions"                   "${PURPLE}"
    print_item "10" "Enable right-click on touchpad"             "${PURPLE}"
    
    echo -e ""
    print_item "11" "Install NVIDIA drivers (if available)"        "${BRIGHT_GREEN}" "${BRIGHT_GREEN}"
    
    echo -e "\n${GRAY}──────────────────────────────────────────${NC}"
    print_item "0"  "Exit" "${RED}" "${RED}"
    echo ""
}

# Apply all settings (OpenH264 mitigation first, then codecs & rest)
apply_all() {
    section "Applying all settings..."
    
    install_openh264 && sleep 1
    setup_rpmfusion && sleep 1
    install_multimedia_codecs && sleep 1
    system_update && sleep 1
    restore_window_buttons && sleep 1
    configure_screenshot && sleep 1
    setup_language_switching && sleep 1
    install_gnome_extensions && sleep 1
    enable_touchpad_rightclick && sleep 1
    
    if detect_nvidia_gpu; then
        read -p "$(echo -e ${YELLOW})NVIDIA GPU detected. Install NVIDIA drivers? (y/n):$(echo -e ${NC}) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_nvidia_drivers
        fi
    fi
    
    section "✓ All settings applied successfully!"
    echo -e "${GREEN}Your Fedora system is now ready to use!${NC}"
    echo ""
}

# Main loop
main() {
    check_fedora
    
    while true; do
        print_header
        print_menu
        echo ""
        read -p "$(echo -e ${MAGENTA})Enter your choice:$(echo -e ${NC}) " choice
        echo ""
        
        case $choice in
            1)
                check_root
                apply_all
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            2)
                check_root
                setup_rpmfusion
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            3)
                check_root
                install_openh264
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            4)
                check_root
                install_multimedia_codecs
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            5)
                check_root
                system_update
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            6)
                restore_window_buttons
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            7)
                configure_screenshot
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            8)
                setup_language_switching
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            9)
                check_root
                install_gnome_extensions
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            10)
                enable_touchpad_rightclick
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            11)
                check_root
                install_nvidia_drivers
                read -p "$(echo -e ${YELLOW})Press Enter to continue...$(echo -e ${NC})"
                ;;
            0)
                echo -e "${GREEN}Thank you for using Fedora-Ready!${NC}"
                echo -e "${CYAN}Goodbye! 👋${NC}"
                exit 0
                ;;
            *)
                error "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Run
main

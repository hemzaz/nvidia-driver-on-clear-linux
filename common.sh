#!/usr/bin/env bash
# common.sh - Shared utility functions for NVIDIA driver scripts
# This file contains common functions used across the driver installation scripts

# Ensure we're running on Clear Linux
function check_clear_linux() {
    local is_clear_linux
    is_clear_linux=$(source "/etc/os-release" 2>/dev/null; echo "$ID")
    
    if [[ "${is_clear_linux}" != "clear-linux-os" ]]; then
        echo "Error: This script must be run on Clear Linux OS."
        return 1
    fi
    return 0
}

# Check for sudo access
function check_sudo() {
    if ! sudo id >/dev/null; then
        echo "Error: This script requires sudo access."
        return 2
    fi
    return 0
}

# Check for required tools
function check_requirements() {
    local missing_tools=()
    
    for tool in "$@"; do
        if ! command -v "${tool}" >/dev/null 2>&1; then
            missing_tools+=("${tool}")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Error: The following required tools are missing:"
        printf "  - %s\n" "${missing_tools[@]}"
        return 3
    fi
    return 0
}

# Check if running in text mode
function check_text_mode() {
    local state
    state=$(systemctl is-active graphical.target 2>&1)
    
    if [[ "${state}" == "active" ]]; then
        return 1
    elif [[ -n $(pidof gnome-shell) || -n $(pidof xdg-desktop-portal) ]]; then
        return 1
    fi
    return 0
}

# Download a file with proper error handling
function download_file() {
    local url="$1"
    local output_file="$2"
    local output_dir
    
    output_dir=$(dirname "${output_file}")
    mkdir -p "${output_dir}"
    
    echo "Downloading ${output_file##*/} from ${url##*/}..."
    if ! curl -L -o "${output_file}" "${url}"; then
        echo "Error: Failed to download ${url}"
        return 4
    fi
    
    if [[ ! -s "${output_file}" || -n $(grep "404 - Not Found" "${output_file}") ]]; then
        rm -f "${output_file}"
        echo "Error: Downloaded file is invalid or not found at URL"
        return 5
    fi
    return 0
}

# Extract version from filename with regex
function extract_version() {
    local filename="$1"
    local version_regex='[0-9]+\.[0-9]+'
    local version
    
    if [[ "${filename}" =~ ${version_regex} ]]; then
        version="${BASH_REMATCH[0]}"
        echo "${version}"
        return 0
    else
        echo "Error: Could not extract version from ${filename}"
        return 6
    fi
}

# Create required directories
function create_directories() {
    local dirs=("$@")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            echo "Creating directory: ${dir}"
            sudo mkdir -p "${dir}"
        fi
    done
}

# Set up cleanup trap
function setup_cleanup() {
    local cleanup_function="$1"
    trap "${cleanup_function}" EXIT INT TERM
}

# Log messages with timestamp
function log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] [${level}] ${message}"
}

# Display script usage
function show_usage() {
    local script_name="$1"
    local usage_text="$2"
    
    echo "Usage: ${script_name} ${usage_text}"
}

# Check DKMS status
function check_dkms() {
    local kernel="$1"
    
    if [[ ! -x "/usr/bin/dkms" ]]; then
        echo "Error: The dkms package is not installed."
        return 7
    fi
    
    if [[ ! -f "/usr/lib/modules/${kernel}/build/Makefile" ]]; then
        echo "Error: The kernel source is not installed for ${kernel}."
        return 8
    fi
    return 0
}

# Load common environment variables
function load_environment() {
    # Get current kernel version
    KERNEL_VERSION=$(uname -r)
    
    # Get Clear Linux OS version
    OS_VERSION=$(source "/etc/os-release"; echo "$VERSION_ID")
    
    # Get current user
    if [[ -n "${SUDO_USER}" ]]; then
        CURRENT_USER="${SUDO_USER}"
    else
        CURRENT_USER="${USER}"
    fi
    
    # Set download directory
    if [[ -e "/usr/bin/xdg-user-dir" ]]; then
        DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD)"
    else
        DOWNLOAD_DIR="/home/${CURRENT_USER}/Downloads"
    fi
    
    # Export variables
    export KERNEL_VERSION
    export OS_VERSION
    export CURRENT_USER
    export DOWNLOAD_DIR
}

# Main initialization function
function init_common() {
    # Exit on error
    set -e
    
    # Load environment variables
    load_environment
    
    # Check if running on Clear Linux
    check_clear_linux || exit $?
    
    # Check required tools: curl, tar, awk
    check_requirements curl tar awk || exit $?
}

# Call init if this script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is a utility script meant to be sourced by other scripts."
    echo "Example: source common.sh"
    exit 1
fi
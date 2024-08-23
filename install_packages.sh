#!/bin/bash

REPO_URL="YOUR_DOTFILES_REPO_URL"

# Function to display usage
usage() {
    echo "Usage: $0 <packages_file>"
    echo "Example: $0 packages.txt"
    exit 1
}

# Check if a packages file is provided
if [ $# -eq 0 ]; then
    usage
fi

packages_file=$1
log_file="installation_log.txt"
failed_packages_file="failed_packages.txt"

# Check if the file exists
if [ ! -f "$packages_file" ]; then
    echo "Error: File '$packages_file' not found."
    usage
fi

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or use sudo"
    exit 1
fi

# Initialize arrays and files
installed_packages=()
failed_packages=()
> "$log_file"
> "$failed_packages_file"

# Function to log messages
log_message() {
    echo "$1" | tee -a "$log_file"
}

# Function to install package
install_package() {
    local package=$1
    log_message "Attempting to install: $package"
    if sudo DEBIAN_FRONTEND=noninteractive apt install -y "$package" >> "$log_file" 2>&1; then
        installed_packages+=("$package")
        log_message "Successfully installed $package"
    else
        failed_packages+=("$package")
        echo "$package" >> "$failed_packages_file"
        log_message "Failed to install $package"
    fi
}

# Update package lists
log_message "Updating package lists..."
sudo apt update >> "$log_file" 2>&1

# Read packages from file and install
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    [[ $line =~ ^#.*$ ]] && continue
    [[ -z "${line// }" ]] && continue

    install_package "$line"
done < "$packages_file"

# Generate summary
summary() {
    echo "============================================"
    echo "            Installation Summary            "
    echo "============================================"
    echo "Total packages attempted: $((${#installed_packages[@]} + ${#failed_packages[@]}))"
    echo "Successfully installed: ${#installed_packages[@]}"
    echo "Failed to install: ${#failed_packages[@]}"
    echo ""
    echo "Installed packages:"
    for pkg in "${installed_packages[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    echo "Failed packages:"
    for pkg in "${failed_packages[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    echo "For detailed information, check:"
    echo "  - Log file: $log_file"
    echo "  - Failed packages list: $failed_packages_file"
    echo "============================================"
}

# Write summary to log and display it
summary | tee -a "$log_file"

log_message "Installation process completed."



# Ask the user if they want to clone the dotfiles repository
read -p "Do you want to clone your default dotfiles repository? (y/n) " response

# Convert the response to lowercase for case-insensitive comparison
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

case "$response" in
    y|yes)
        # Clone the repository into the home directory
        git clone "$REPO_URL" ~/dotfiles

        # Change directory to the newly cloned repository
        cd ~/dotfiles || exit

        # Run stow to manage the dotfiles
        stow .
        echo "repository cloned and Initialized!"
        ;;
    n|no)
        echo "No action taken."
        ;;
    *)
        echo "Invalid response. Please enter 'y' or 'n'."
        ;;
esac

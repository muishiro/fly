#!/bin/bash

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Attempting to install Git..."
    
    # Use apt to install git
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install git -y
    else
        echo "Cannot install Git automatically using apt. Please install Git manually and run this script again."
        exit 1
    fi
    
    # Check again if git is installed after attempting to install
    if ! command -v git &> /dev/null; then
        echo "Git installation failed. Please install Git manually and run this script again."
        exit 1
    fi
fi

echo "Git is installed. Continuing with the script..."


fly_config_file="/etc/ly/config.ini"

# Clone the repository and check for errors
git clone --recurse-submodules https://github.com/fairyglade/ly /tmp/ly || { echo "Failed to clone repository"; exit 1; }

# Change to the repository directory and check for errors
cd /tmp/ly || { echo "Failed to change directory to /tmp/ly"; exit 1; }

# Checkout the specific commit and check for errors
git checkout 4ee2b3e || { echo "Failed to checkout commit"; exit 1; }

# Update submodules and check for errors
git submodule update --init --recursive || { echo "Failed to update submodules"; exit 1; }

# Build and install
make || { echo "Build failed"; exit 1; }
sudo make install installsystemd || { echo "Installation failed"; exit 1; }

# Enable and disable systemd services
sudo systemctl enable ly.service || { echo "Failed to enable ly.service"; exit 1; }
sudo systemctl disable getty@tty2.service || { echo "Failed to disable getty@tty2.service"; exit 1; }

# Check if the config file exists
if [[ -f $fly_config_file ]]; then
    echo "Appending configuration to $fly_config_file"
else
    echo "$fly_config_file does not exist."
    echo "Please manually add you configuration."
    exit 1;
fi

# Append configuration to /etc/ly/res/config.ini
cat << EOF | sudo tee -a $fly_config_file > /dev/null
# xinitrc
xinitrc = ~/.xinitrc
# Xorg server command
x_cmd = /usr/bin/X > /dev/null 2>&1
# Xorg setup command
x_cmd_setup = /etc/ly/xsetup.sh
# Xorg xauthority edition tool
xauth_cmd = /usr/bin/xauth
# Xorg desktop environments
xsessions = /usr/share/xsessions
EOF

echo "ly login manager installed"


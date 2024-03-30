#!/bin/bash

# Check if root  
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Install libpam-cracklib
apt-get install libpam-cracklib -y || { echo "Error installing libpam-cracklib"; exit 1; }

# Get parameters as input
read -p "Enter minimum password length (minlen): " minlen
read -p "Enter allowed number of same consecutive characters (difok): " difok
read -p "Enter minimum uppercase letters required (ucredit): " ucredit
read -p "Enter minimum lowercase letters required (lcredit): " lcredit
read -p "Enter minimum digits required (dcredit): " dcredit
read -p "Enter minimum special characters required (ocredit): " ocredit

# Backup previous config file
cp /etc/pam.d/common-password /etc/pam.d/common-password.bak || { echo "Error taking backup"; exit 1; }

# Set cracklib rules
cat <<EOF > /etc/pam.d/common-password  
password required pam_cracklib.so minlen=$minlen difok=$difok ucredit=$ucredit lcredit=$lcredit dcredit=$dcredit ocredit=$ocredit
password required pam_cracklib.so retry=3 minlen=$minlen difok=$difok ucredit=$ucredit lcredit=$lcredit dcredit=$dcredit ocredit=$ocredit 
EOF

echo "Setup completed successfully"

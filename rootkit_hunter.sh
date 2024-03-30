#!/bin/bash

# Function to print colored text
print_colored() {
  local color="$1"
  local text="$2"
  echo -e "\e[${color}m${text}\e[0m"
}

# Function to install Rootkit Hunter
install_rkhunter() {
  if ! command -v rkhunter &> /dev/null; then
    echo "Rootkit Hunter is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y rkhunter
  fi
}

# Function to configure Rootkit Hunter
configure_rkhunter() {
  print_colored "32" "Configuring Rootkit Hunter..."

  # Update the Rootkit Hunter database
  sudo rkhunter --update

  # Run Rootkit Hunter checks
  print_colored "32" "Running Rootkit Hunter checks..."
  sudo rkhunter --check

  # Prompt user for cron job setup
  read -p "Do you want to set up a daily cron job for Rootkit Hunter? (y/n): " cron_choice
  if [ "$cron_choice" == "y" ]; then
    print_colored "32" "Setting up daily cron job for Rootkit Hunter..."
    (crontab -l 2>/dev/null; echo "0 0 * * * /usr/bin/rkhunter --cronjob --update --quiet") | crontab -
  else
    print_colored "33" "Cron job not set up. You can manually run 'sudo rkhunter --check' for periodic checks."
  fi

  print_colored "32" "Rootkit Hunter configuration completed."
}

# Quit functionality
read -p "Do you want to continue? (y/n): " choice
if [ "$choice" != "y" ]; then
  echo "Exiting script."
  exit 0
fi

# Install Rootkit Hunter
install_rkhunter

# Configure Rootkit Hunter
configure_rkhunter


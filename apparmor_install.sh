#!/bin/bash

# Check for root privilages  
if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit
fi

# Install Apparmor (if not already)
if ! [ -x "$(command -v apparmor_parser)" ]; then  
  apt -y install apparmor apparmor-profiles apparmor-utils

  # Load system profiles
  apparmor_parser -r /etc/apparmor.d/*
  systemctl restart apparmor
fi  

# Apparmor profiles path
apparmor_path="/etc/apparmor.d" 

# Available profiles  
profiles=("usr.sbin.apache2" "usr.sbin.mysqld" "nginx" "usr.bin.php" "tcpdump")

echo "Select profiles:"

# Display profiles menu
select profile in "${profiles[@]}" Quit; do 
  if [ "$REPLY" == "6" ]; then
    break
  elif [[ " ${profiles[*]} " =~ " $profile " ]]; then
    apparmor_parser -r "$apparmor_path/$profile"
    echo "$profile enabled"
  else
    echo "Invalid choice"
  fi  
done

echo "Profiles configured successfully"

#!/bin/bash

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mChecking if logged in as root.\e[0m"

#Run script as root
if [ "$EUID" -ne 0 ]
	  then echo "Please run as root"
		    exit
fi

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mUpdating Packages.\e[0m"

# Update packages
apt update
apt upgrade -y

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mInstalling LAMP stack.\e[0m"

# Install lamp packages
apt install apache2 mysql-server php libapache2-mod-php php-mysql -y

# Enable modules
a2enmod php7.4
a2enmod rewrite

# Restart Apache
systemctl restart apache2

# Secure MySQL
mysql_secure_installation

# Set MySQL password
mysqladmin -u root password 'strongpassword'

# Check versions 
apache2 -v
mysql -V
php -v

# Set permissions on web folder
chown -R www-data:www-data /var/www/html

# Completed
echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mLAMP stack installed.\e[0m"

# Install PAM

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mInstalling and Configuring PAM.\e[0m"

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

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mSet up successfully.\e[0m"

# Immutability
echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mEnabling Immutability.\e[0m"

# Prompt the user for a file path
read -p "Enter the path of the file: " file_path

# Check if the file path is empty
if [ -z "$file_path" ]; then
    echo "No file provided. Exiting without making changes."
fi

# Check if the file exists
if [ ! -e "$file_path" ]; then
    echo "File does not exist. Exiting without making changes."
fi

# Make the file immutable using chattr
chattr +i "$file_path"

# Check if chattr command was successful
if [ $? -eq 0 ]; then
    echo "File $file_path is now immutable."
else
    echo "Failed to make the file immutable."
fi

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mInstalling and Configuring Wordpress.\e[0m"
# Installing wordpress
# Create DB and user
mysql -e "CREATE DATABASE wordpress;"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost IDENTIFIED BY 'strongpassword';"

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mInstalling Dependencies .\e[0m"
# Install dependencies 
apt install php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip -y

# Setup web directories
mkdir -p /var/www/html
cd /var/www/html

# Download and extract WordPress
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz 
cp -r wordpress/* /var/www/html  

# Set permissions
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/ 

# Configure WordPress 
mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/database_name_here/wordpress/g" /var/www/html/wp-config.php
sed -i "s/root/wordpress/g" /var/www/html/wp-config.php  
sed -i "s/strongpassword/strongpassword/g" /var/www/html/wp-config.php

# Restart web server 
systemctl restart apache2

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mWordPress Installed.\e[0m"

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mMySQL Hardening.\e[0m"

#MySQL hardening

# Functions for input and errors
read_input(){
  read -p "$1: " var
  if [ -z "$var" ]; then
    echo "Invalid input provided" 
  fi
}

handle_error(){
  echo "An error occurred: $1" >&2
}

# Take inputs
read_input "Enter MySQL root password" mysql_pass
read_input "Enter SSL/TLS certificate path" server_cert 
read_input "Enter certificate key path" server_key

# Install MySQL 
apt-get install mysql-server -y || handle_error "MySQL install failed"

# Configure TLS in my.cnf
echo -e "[mysqld]\nssl-cert = $server_cert\nssl-key = $server_key" > /etc/mysql/conf.d/tls.cnf || handle_error "TLS config failed"  

# Restart MySQL service
service mysql restart || handle_error "Service restart failed"  

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mMySQL hardened and TLS encryption enabled.\e[0m"

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mInstalling Apparmor.\e[0m"

# Installing Apparmor
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
echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mProfiles configured successfully.\e[0m"

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mInstalling Rootkit Hunter.\e[0m"
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
fi

# Install Rootkit Hunter
install_rkhunter

# Configure Rootkit Hunter
configure_rkhunter

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mInstalling Auditd.\e[0m"
#!/bin/bash

# Function to print colored text
print_colored() {
  local color="$1"
  local text="$2"
  echo -e "\e[${color}m${text}\e[0m"
}

# Function to install auditd
install_auditd() {
  if ! command -v auditd &> /dev/null; then
    echo "auditd is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install -y auditd
  fi
}

# Function to configure auditd
configure_auditd() {
  print_colored "32" "Configuring auditd..."

  # Prompt user for audit rule setup
  read -p "Do you want to set up custom audit rules? (y/n): " audit_rule_choice
  if [ "$audit_rule_choice" == "y" ]; then
    read -p "Enter the custom audit rule: " custom_audit_rule
    sudo auditctl -a "$custom_audit_rule"
  else
    print_colored "33" "No custom audit rules set up."
  fi

  # Enable auditd
  sudo systemctl enable auditd
  sudo systemctl start auditd

  print_colored "32" "auditd configuration completed."
}

# Quit functionality
read -p "Do you want to continue? (y/n): " choice
if [ "$choice" != "y" ]; then
  echo "Exiting script."
fi

# Install auditd
install_auditd

# Configure auditd
configure_auditd

echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mPacket Analysis.\e[0m"

# Function to print colored text
print_colored() {
  local color="$1"
  local text="$2"
  echo -e "\e[${color}m${text}\e[0m"
}

# Prompt the user for a file name
read -p "Enter the path to the packet capture file (or type 'quit' to exit): " pcap_file

# Check if the user wants to quit
if [ "$pcap_file" == "quit" ]; then
  echo -e "\e[38;2;255;0;0;48;2;0;0;255;1mExiting the script. No analysis performed.\e[0m"
  exit 0
fi

# Check if tshark is installed
if ! command -v tshark &> /dev/null; then
  echo "tshark is not installed. Installing..."
  sudo apt-get update
  sudo apt-get install -y tshark
fi

# Check if the file exists
if [ ! -f "$pcap_file" ]; then
  echo "Error: File '$pcap_file' not found."
  exit 1
fi

# Perform packet analysis using tshark
tshark -r "$pcap_file" -T fields -e frame.number -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport -e udp.srcport -e udp.dstport -e http.request.method -e http.host -e http.request.uri -E header=y -E separator=, | while IFS=, read -r frame ip_src ip_dst tcp_src_port tcp_dst_port udp_src_port udp_dst_port http_method http_host http_uri; do

  # Print packet information with colored text
  print_colored "36" "Frame: $frame"
  print_colored "32" "IP Source: $ip_src"
  print_colored "31" "IP Destination: $ip_dst"
  print_colored "33" "TCP Source Port: $tcp_src_port"
  print_colored "33" "TCP Destination Port: $tcp_dst_port"
  print_colored "34" "UDP Source Port: $udp_src_port"
  print_colored "34" "UDP Destination Port: $udp_dst_port"
  print_colored "35" "HTTP Method: $http_method"
  print_colored "35" "HTTP Host: $http_host"
  print_colored "35" "HTTP URI: $http_uri"

  echo "--------------------------------------"
done



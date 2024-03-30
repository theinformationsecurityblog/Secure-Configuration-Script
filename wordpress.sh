#!/bin/bash

# Run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Create DB and user
mysql -e "CREATE DATABASE wordpress;"
mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost IDENTIFIED BY 'strongpassword';"

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

echo "WordPress Installed"


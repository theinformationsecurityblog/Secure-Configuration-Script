#!/bin/bash

#Run script as root
if [ "$EUID" -ne 0 ]
	  then echo "Please run as root"
		    exit
fi

# Update packages
apt update
apt upgrade -y

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
echo "LAMP stack installed"

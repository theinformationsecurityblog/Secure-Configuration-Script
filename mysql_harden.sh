#!/bin/bash

# Check if root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Functions  
read_input(){
  read -p "$1: " var
  if [ -z "$var" ]; then
    echo "Invalid input provided"
    exit 1 
  fi
}

error_exit(){
  echo "Failed - $1" >&2
  exit 1
}

# Take inputs  
read_input "Enter MySQL root password" mysql_root_pass
read_input "Enter MySQL user password" mysql_user_pass
read_input "Enter certificate path" server_cert
read_input "Enter certificate key path" server_key

# Install MySQL and OpenSSL
apt-get install mysql-server openssl -y || error_exit "Package install failed"

# MySQL Hardening
useradd mysqluser && mysql -u root --password="$mysql_root_pass" -e "CREATE USER 'mysqluser'@'localhost' IDENTIFIED BY '$mysql_user_pass'; GRANT ALL PRIVILEGES ON *.* TO 'mysqluser'@'localhost';" || error_exit "User creation failed"

# TLS Configuration
echo -e "[mysqld]\nssl-cert = $server_cert\nssl-key = $server_key" > /etc/mysql/conf.d/ssl.cnf || error_exit "TLS config failed"  
service mysql restart || error_exit "Service restart failed"

echo "MySQL hardened and TLS enabled"

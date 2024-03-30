#!/bin/bash

# Install easy-rsa
apt-get install easy-rsa -y

if [ $? -ne 0 ]; then
  echo "Error installing easy-rsa" 
  exit 1
fi

# Get inputs 
# ...

# Initialize PKI 
if [ $? -ne 0 ]; then
  echo "Error creating PKI directory"
  exit 1 
fi 

/usr/share/easy-rsa/easyrsa init-pki
if [ $? -ne 0 ]; then
  echo "Error initializing PKI" 
  exit 1  
fi

# Generate CA cert
/usr/share/easy-rsa/easyrsa --batch "--req-cn=$ca_name CA" build-ca nopass 
if [ $? -ne 0 ]; then
  echo "Error building CA certificate"
  exit 1
fi

echo "CA certificate setup successfully"

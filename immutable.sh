#!/bin/bash

# Check if run as root 
if [ "$EUID" -ne 0 ]  
	  then echo "Please run as root"
		    exit
fi

#Check if filename argument is passed
if [ -z "$1" ]; then
	  echo "Error: No filename passed"
	    echo "Usage: $0 <filename>" 
	      exit 1
fi

# Assign filename 
filename=$1

# Validate file exists
if [ ! -f "$filename" ]; then
	    echo "Error: File $filename not found"
	        exit 1
fi

# Make file immutable
chattr +i "$filename"

echo "File '$filename' is now immutable"

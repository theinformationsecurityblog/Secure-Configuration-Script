#!/bin/bash

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


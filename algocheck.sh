#!/bin/bash

# Set the algorithms to benchmark
algorithms=("aes-256-cbc" "aes-256-gcm" "sha256" "sha512")

# Output file for benchmark results
output_file="benchmark_results.txt"

# Function to log messages
log() {
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $1" >> "$output_file"
}

# Function to perform the benchmark for a given algorithm
benchmark_algorithm() {
  local algorithm="$1"
  local iterations=1000  # Adjust the number of iterations as needed

  log "Benchmarking $algorithm..."
  
  # Perform the benchmark and measure the time taken
  local start_time
  start_time=$(date +%s.%N)
  
  # Add your OpenSSL command here based on the algorithm
  case "$algorithm" in
    "aes-256-cbc")
      openssl enc -aes-256-cbc -in /dev/zero -out /dev/null -iterations "$iterations"
      ;;
    "aes-256-gcm")
      openssl enc -aes-256-gcm -in /dev/zero -out /dev/null -iterations "$iterations"
      ;;
    "sha256")
      openssl speed sha256
      ;;
    "sha512")
      openssl speed sha512
      ;;
    *)
      log "Unsupported algorithm: $algorithm"
      return 1
      ;;
  esac
  
  local end_time
  end_time=$(date +%s.%N)
  
  local duration
  duration=$(echo "$end_time - $start_time" | bc)

  log "$algorithm benchmark completed in $duration seconds"
}

# Check if OpenSSL is installed
if ! command -v openssl &> /dev/null; then
  echo "Error: OpenSSL is not installed. Please install OpenSSL before running this script."
  exit 1
fi

# Check if the output file exists, create if not
if [ ! -e "$output_file" ]; then
  touch "$output_file"
fi

# Perform benchmarks for each algorithm
for algorithm in "${algorithms[@]}"; do
  benchmark_algorithm "$algorithm"
done

echo "Benchmarking complete. Results logged to $output_file"


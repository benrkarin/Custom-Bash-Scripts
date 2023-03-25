#!/bin/bash

# Help menu
help_menu() {
  echo ""
  echo "Usage: $0 -i <input_file> -o <output_file> -n <num_lines>"
  echo ""
  echo "  -i <input_file>: input file name"
  echo "  -o <output_file>: output file name (optional, default is input file with '_burnin' appended to the name)"
  echo "  -n <num_lines>: number of lines to remove (integer or percentage with % symbol)"
  echo ""
}

# Parse command line arguments
while getopts ":i:o:n:h" opt; do
  case $opt in
    i)
      input_file="$OPTARG"
      ;;
    o)
      output_file="$OPTARG"
      ;;
    n)
      num_lines="$OPTARG"
      ;;
    h)
      help_menu
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      help_menu
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      help_menu
      exit 1
      ;;
  esac
done

# Check if the input file argument is provided
if [ -z "$input_file" ]; then
  echo "Input file is not specified."
  help_menu
  exit 1
fi

# Use the input file name with '_burnin' appended as the output file name if not provided
if [ -z "$output_file" ]; then
  output_file="${input_file}_burnin"
fi

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  echo "File not found: $input_file"
  exit 1
fi

# Get the total number of lines in the file
total_lines=$(wc -l < "$input_file")

# Check if the number of lines to remove is specified as a percentage
if [[ "$num_lines" == *% ]]; then
  # Calculate the actual number of lines to remove
  num_lines_percent=${num_lines%\%}
  num_lines=$((total_lines * num_lines_percent / 100))
fi

# Check if the number of lines to remove is greater than the total number of lines
if [ "$num_lines" -ge "$total_lines" ]; then
  echo "Number of lines to remove is greater than or equal to the total number of lines"
  exit 1
fi

# Calculate the number of lines to retain
num_retain=$((num_lines + 1))

# Create a temporary file with the remaining lines (including the header)
head -n 1 "$input_file" > "$output_file"
tail -n +$num_retain "$input_file" >> "$output_file"

echo "Removed first $num_lines line(s) from $input_file and saved to $output_file"

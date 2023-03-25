#!/bin/bash

# Define usage function
function usage {
  echo ""
  echo "Usage: $0 -i input_file [-o output_file] [-m multiplier]"
  echo ""
  echo "Description: This script multiplies all decimal numbers in a tree file by a multiplier, useful for converting coalescence times to millions of years. Taxon names must NOT have decimal numbers in them or they will be multiplied."
  echo ""
  echo "  -i input_file: Specifies the input file."
  echo "  -o output_file: Specifies the output file. If not specified, the output file will be named input_file_out."
  echo "  -m multiplier: Specifies the multiplier to use. Default is 1000."
  echo "  -h: Displays this help message."
  echo ""
}

# Set default multiplier
multiplier=1000

# Parse command line arguments
while getopts ":i:o:m:h" opt; do
  case $opt in
    i)
      input_file=$OPTARG
      ;;
    o)
      output_file=$OPTARG
      ;;
    m)
      multiplier=$OPTARG
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done

# Check if input file is specified
if [ -z "$input_file" ]; then
  echo "Input file not specified. Use the -i flag to specify the input file."
  usage
  exit 1
fi

# Check if input file exists
if [ ! -f "$input_file" ]; then
  echo "Input file $input_file does not exist."
  usage
  exit 1
fi

# Set default output file if not specified
if [ -z "$output_file" ]; then
  output_file="${input_file%.*}_out.${input_file##*.}"
fi

# Search for multi-digit decimal numbers after a ":" and multiply them by the specified multiplier
# read file line by line
while read -r line; do
  # find all numbers with decimals in the line using grep
  decimals=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+')

  # loop through each decimal and multiply by 1000
  for decimal in $decimals; do
    multiplied=$(echo "scale=3; $decimal * $multiplier" | bc)
    line=$(echo "$line" | sed "s/$decimal/$multiplied/")
  done

  echo "$line"
done < "$input_file" > "$output_file"

#sed -E "s/:[[:space:]]*([0-9]+(\.[0-9]+)?)/: \1*$multiplier/g" "$input_file" > "$output_file"

echo "Done! Output saved to $output_file."



#!/bin/bash

# Define variables for default values
default_output_dir_suffix="-rmTaxa"
default_output_dir=""

# Define usage function for help menu
function usage {
  echo ""
  echo "Usage: $(basename "$0") [-h] [-i INPUT_DIR] [-o OUTPUT_DIR] [-t SEARCH_TAXON] [-l LIST_FILE]"
  echo ""
  echo "Description: Filters FASTA files in INPUT_DIR or listed in LIST_FILE by searching for SEARCH_TAXON using seqkit grep and writes the filtered output to OUTPUT_DIR."
  echo ""
  echo "Options:"
  echo "  -h              Display help menu"
  echo "  -i INPUT_DIR    Input directory containing FASTA files"
  echo "  -o OUTPUT_DIR   Output directory for filtered FASTA files. If not specified, uses INPUT_DIR with '-rmTaxa' suffix."
  echo "  -t SEARCH_TAXON Taxon to search for using seqkit grep. Can be a text string or a file containing a list of taxons."
  echo "  -l LIST_FILE    File containing a list of FASTA files to process. If specified, overrides INPUT_DIR."
}

# Parse command line arguments
while getopts ":i:o:t:l:h" opt; do
  case $opt in
    i) input_dir="$OPTARG"
    ;;
    o) output_dir="$OPTARG"
    ;;
    t) search_taxon="$OPTARG"
    ;;
    l) list_file="$OPTARG"
    ;;
    h) usage; exit 0
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
        usage
        exit 1
    ;;
  esac
done

# If input directory or search taxon is not specified, print usage and exit
if [ -z "${input_dir}" ] || [ -z "${search_taxon}" ]; then
  usage
  exit 1
fi

# If output directory is not specified, use default
if [ -z "${output_dir}" ]; then
    default_output_dir="${input_dir%/}${default_output_dir_suffix}"
    echo "Output directory not specified. Using default: ${default_output_dir}"
    output_dir="${default_output_dir}"
fi

# Create output directory if it doesn't exist
if [ -d "${output_dir}" ]; then
    read -p "Output directory ${output_dir} already exists. Do you want to overwrite it? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Overwriting output directory ${output_dir}..."
        rm -r "${output_dir}"
    else
        echo "Exiting without overwriting output directory ${output_dir}."
        exit 1
    fi
fi
echo "Creating output directory ${output_dir}..."
mkdir -p "${output_dir}"

# Process either all FASTA files in input directory or those listed in file
if [ -z "${list_file}" ]; then
    echo "No list file specified. Processing all FASTA files in input directory..."

    # Determine if search_taxon is a file or a text string
    if [ -f "${search_taxon}" ]; then
        echo "Search taxon is a file. Using seqkit grep with -f flag..."

        # Loop over all FASTA files in input directory
        for file in "${input_dir%/}"/*.fasta; do
            # Extract filename without extension
            filename=$(basename "${file%.*}")

            # Run seqkit grep with -f flag and specified arguments
            seqkit grep -n -v -r -f "${search_taxon}" "${file}" > "${output_dir%/}/${filename}.fasta"
        done
    else
        echo "Search taxon is a text string. Using seqkit grep with -p flag..."

        # Loop over all FASTA files in input directory
        for file in "${input_dir%/}"/*.fasta; do
            # Extract filename without extension
            filename=$(basename "${file%.*}")

            # Run seqkit grep with -
            seqkit grep -n -v -r -p "${search_taxon}" "${file}" > "${output_dir%/}/${filename}.fasta"
        done
    fi
else
    echo "List file specified. Processing FASTA files listed in ${list_file}..."

    # Determine if search_taxon is a file or a text string
    if [ -f "${search_taxon}" ]; then
        echo "Search taxon is a file. Using seqkit grep with -f flag..."

        # Loop over all FASTA files listed in file
        while read -r file; do
            # Extract filename without extension
            filename=$(basename "${file%.*}")

            if [ -e "${input_dir%/}/${file}" ]; then

              # Run seqkit grep with -f flag and specified arguments
              seqkit grep -n -v -r -f "${search_taxon}" "${input_dir%/}/${file}" > "${output_dir%/}/${filename}.fasta"
            else
                echo "File ${file} does not exist in input directory"
            fi
        done < "${list_file}"
    else
        echo "Search taxon is a text string. Using seqkit grep with -p flag..."

        # Loop over all FASTA files listed in file
        while read -r file; do
            # Extract filename without extension
            filename=$(basename "${file%.*}")
            if [ -e "${input_dir%/}/${file}" ]; then
            # Run seqkit grep with -p flag and specified arguments
              seqkit grep -n -v -r -p "${search_taxon}" "${input_dir%/}/${file}" > "${output_dir%/}/${filename}.fasta"
            else 
                echo "File ${file} does not exist in input directory. Skipping"
            fi
        done < "${list_file}"
    fi
    
    for file in $(ls ${input_dir%/}); do
    # Check if file is in the list file
    if ! grep -q "$file" "${list_file}"; then
        # Copy file to the output directory
        cp "${input_dir%/}/$file" "${output_dir%/}/$file"
        echo "$file not in fasta filter list, copying directly without filtering"
    fi
done
fi

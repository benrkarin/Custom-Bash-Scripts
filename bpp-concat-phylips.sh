#!/bin/bash

# Get the input directory and output file names from the command line arguments
input_dir=$1
output_file=$2

# Loop over the Phylip files in the input directory
for file in $input_dir/*.phy; do

    # Get the base filename without the extension
    base=$(basename $file .phy)

    # Get the number of sequences and the length of each sequence from the input file
    num_seqs=$(head -n 1 $file | awk '{print $1}')
    seq_len=$(head -n 1 $file | awk '{print $2}')

    # Write the modified Phylip block to the output file
    #echo "$base" >> $output_file
    echo "$num_seqs $seq_len" >> $output_file
    tail -n +2 $file | while read line; do
        if [[ ! -z "$line" ]]; then
            seq_name=$(echo $line | awk '{print $1}')
            seq=$(echo $line | awk '{print $2}')
            seq_name="^$seq_name"
            echo "$seq_name $seq" >> $output_file
        else
            echo "" >> $output_file
        fi
    done
    echo "" >> $output_file
done

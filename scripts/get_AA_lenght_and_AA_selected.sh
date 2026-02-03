#!/bin/bash

# Define the input files
fasta_file_list="positive_sel_pal2nal_fdr.txt"
alt_out_file_list="positive_sel_alt_out_fdr.txt"

# Temporary files
length_file="length_fdr.txt"
beb2_file="beb2_fdr.txt"
updated_beb2_file="updated_beb2_fdr.txt"

# Step 1: Process FASTA files to compute sequence lengths
while IFS= read -r fasta_file; do
    if [ -f "$fasta_file" ]; then
        first_sequence=$(awk '/^>/ {if (seq) exit} {if (!/^>/) seq=seq$0} END {print seq}' "$fasta_file")
        sequence_length=${#first_sequence}
        result=$((sequence_length / 3))
        echo -e "${fasta_file}\t${result}"
    else
        echo -e "${fasta_file}\tFile not found"
    fi
done < "$fasta_file_list" > "$length_file"

sed -i 's/.pal2nal//' "$length_file"

# Step 2: Process .alt.out files for specific matches
while IFS= read -r filename; do
    if [ -f "$filename" ]; then
        matches=$(grep -A 20 "(BEB)" "$filename" | grep "*" | awk '{printf "%s\t", $0}')
        if [ -n "$matches" ]; then
            echo -e "${filename}\t${matches}"
        else
            echo -e "${filename}\tNo matches found"
        fi
    else
        echo -e "${filename}\tFile not found"
    fi
done < "$alt_out_file_list" > "$beb2_file"

sed -i 's/.alt.out//' "$beb2_file"
sed -i -e 's/\*\s\+/*\t/g' -e 's/\.1\s\+/\.1\t/g' "$beb2_file"

# Step 3: Process files with Python to combine results
python3 <<EOF
import sys

def read_file(file_path):
    data = {}
    try:
        with open(file_path, 'r') as f:
            for line in f:
                parts = line.strip().split('\t')
                if len(parts) == 2:
                    data[parts[0]] = parts[1]
    except Exception as e:
        print(f"Error reading {file_path}: {e}", file=sys.stderr)
    return data

def write_file(file_path, data):
    try:
        with open(file_path, 'w') as f:
            for key, value in data.items():
                f.write(f"{key}\t{value}\n")
    except Exception as e:
        print(f"Error writing {file_path}: {e}", file=sys.stderr)

def merge_files(length_file, beb2_file, output_file):
    length_data = read_file(length_file)
    beb2_data = {}

    try:
        with open(beb2_file, 'r') as f:
            for line in f:
                parts = line.strip().split('\t', 1)
                if len(parts) == 2:
                    file_name, matches = parts
                    length_info = length_data.get(file_name, 'Length not found')
                    beb2_data[file_name] = f"{length_info}\t{matches}"
    except Exception as e:
        print(f"Error reading {beb2_file}: {e}", file=sys.stderr)

    write_file(output_file, beb2_data)

# Run the merge operation
merge_files('$length_file', '$beb2_file', '$updated_beb2_file')
EOF

echo "Processing complete. Results saved in $updated_beb2_file."

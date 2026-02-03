#!/bin/bash
set -euo pipefail

# ---------- STEP 1: Build combined.tsv from all .tsv files ----------
> combined.tsv

for file in *.tsv; do
    awk -F'\t' '{
        n = split($2, a, ",");
        for (i = 1; i <= n; i++) {
            print $1 "\t" a[i]
        }
    }' "$file" >> combined.tsv
done

# Remove single spaces, then sort uniquely
sed -i 's/ //' combined.tsv
sort -u combined.tsv -o combined.tsv


# ---------- STEP 2: Grep peptides into individual files ----------
while IFS=$'\t' read -r col1 col2; do
    grep -H "$col2" *pep.tsv > "${col2}.tsv"
done < combined.tsv


# ---------- STEP 3: Remove unwanted *1.tsv files containing commas ----------
find . -type f -name "*1.tsv" -exec grep -q ',' {} \; -exec rm {} +


# ---------- STEP 4: Process remaining .tsv files into final .txt outputs ----------
for input_file in *.tsv; do
    # Extract pattern from first column (first line only)
    pattern=$(awk -F'\t' 'NR==1 {print $1}' "$input_file" | cut -d':' -f2)

    # Skip if pattern is empty
    [[ -z "$pattern" ]] && continue

    output_file="${pattern}_${input_file%.tsv}.txt"

    awk -F'\t' '{print $2, $3}' "$input_file" \
        | sed 's/ /\n/' \
        | sort -u \
        > "$output_file"

    echo "Processed $input_file → $output_file"
done

# ---------- STEP 5: Convert *1.txt files to both transcript and protein FASTA using cdbyank ----------
for file in *1.txt; do
    # Transcript FASTA
    transcript_output="${file}.transcript.fasta"
    > "$transcript_output"  # Create or clear the output file
    while IFS= read -r accession; do
        cdbyank AllCleanTranscripts.fasta.cidx -a "$accession" >> "$transcript_output"
    done < "$file"
    echo "Generated $transcript_output from $file"

    # Protein FASTA
    protein_output="${file}.protein.fasta"
    > "$protein_output"  # Create or clear the output file
    while IFS= read -r accession; do
        cdbyank AllCleanProteins.fasta.cidx -a "$accession" >> "$protein_output"
    done < "$file"
    echo "Generated $protein_output from $file"
done

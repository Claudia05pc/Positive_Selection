#!/bin/bash
# Usage: ./script.sh TAXON
# Example: ./script.sh ENSOT

if [ -z "$1" ]; then
    echo "Please provide the taxon to match."
    echo "Usage: $0 TAXON"
    exit 1
fi

MATCH_TAXON="$1"
PREFIX="TMP"       # Temporary prefix to be removed later
EXT="*contree"

# Step 1: Add temporary prefix and #1 mark after the chosen taxon
for file in $EXT; do
    sed -E -i.bak \
        -e "s/($MATCH_TAXON)([,(])/${PREFIX}_\1 #1\2/g" \
        -e "s/$MATCH_TAXON/${PREFIX}_$MATCH_TAXON/g" \
        "$file"
done

# Step 2: Ensure all occurrences of the prefixed taxon get #1 after them
for file in $EXT; do
    sed -E -i \
        -e "s/(${PREFIX}_[^,()]*)([),])/\1 #1\2/g" \
        "$file"
done

# Step 3: Remove the temporary prefix
for file in $EXT; do
    sed -i "s/${PREFIX}_//g" "$file"
done

# Step 4: Cleanup backup files
rm -f *.bak

echo "Done! Processed files: $EXT"

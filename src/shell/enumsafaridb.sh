#!/usr/bin/env sh

DB_PATH="/Users/darmado/Library/Containers/com.apple.Safari"
OUTPUT_FILE="safari_all_dbs_data_all.txt"

> "$OUTPUT_FILE"

# Loop through all .db files found in the specified directory
find "$DB_PATH" -name "*.db" | while read -r db; do
    echo "[+] Processing: $db ##" >> "$OUTPUT_FILE"

    # Enable headers and column mode for better readability
    sqlite3 "$db" <<EOF >> "$OUTPUT_FILE"
.headers on
.mode column
.tables
EOF

    # List tables into a temporary file
    sqlite3 "$db" ".tables" | tr ' ' '\n' > tables.txt

    # Iterate through each line in tables.txt to get each table name
    while read -r table; do
        if [ ! -z "$table" ]; then
            echo "Table: $table ##" >> "$OUTPUT_FILE"
            
            # Get column information and sample data
            sqlite3 "$db" <<EOF >> "$OUTPUT_FILE"
.headers on
.mode column
PRAGMA table_info($table);
SELECT * FROM $table ;
EOF
        fi
    done < tables.txt
    
    echo "\n\n## DONE ## $db" >> "$OUTPUT_FILE"
done

# Clean up
rm tables.txt

# Zip the output file
zip -q safari_all_dbs_data_all.zip "$OUTPUT_FILE"

# Remove the original text file after zipping
rm "$OUTPUT_FILE"

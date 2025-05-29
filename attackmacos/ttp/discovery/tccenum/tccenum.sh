
# Path to the TCC database
TCC_DB_PATH="/Library/Application Support/com.apple.TCC/TCC.db"

# Check if the TCC database exists
if [ ! -f "$TCC_DB_PATH" ]; then
    echo "TCC database not found at $TCC_DB_PATH"
    exit 1
fi

# Query the TCC database for ApplicationPassword keys
sqlite3 "$TCC_DB_PATH" "SELECT * FROM access WHERE service='kTCCServiceApplicationPassword';"

# Alternatively, to count the entries
# sqlite3 "$TCC_DB_PATH" "SELECT count(*) FROM access WHERE service='kTCCServiceApplicationPassword';"

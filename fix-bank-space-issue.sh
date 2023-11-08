#!/bin/bash

# Function to fix file names
fix_file_name() {
    local file="$1"
    local new_name="$(echo $file | tr ' ' '_')" # Replace spaces with underscores
    if [[ "$file" != "$new_name" ]]; then
        mv "$file" "$new_name"
        echo "Renamed file: $file -> $new_name"
    fi
}

# Function to run sqlplus
run_sqlplus() {
    local file="$1"
    # Assuming 'sqlplus' is in the PATH and your Oracle credentials are set up
    # You will need to replace 'username/password@db' with your actual credentials or setup
    sqlplus username/password@db @"$file"
}

export -f fix_file_name
export -f run_sqlplus

# Find all .sql files with spaces in their names
find . -name "*.sql" -type f | grep ' ' | while read -r file; do
    fix_file_name "$file"
done

# Now, run sqlplus with all fixed .sql files
find . -name "*.sql" -type f | while read -r file; do
    run_sqlplus "$file"
done

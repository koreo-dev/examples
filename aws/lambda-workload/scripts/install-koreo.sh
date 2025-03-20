#!/usr/bin/env bash

# Usage function
usage() {
  echo "Usage: $0 <source_directory>"
  exit 1
}

# Validate argument count
if [ $# -ne 2 ]; then
  usage
fi

# Set the directory containing the files and the namespace
SOURCE_DIR="$1"

# Check if the source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Directory $SOURCE_DIR does not exist."
  exit 1
fi

# Process each directory containing .koreo files
for DIR in $(find "$SOURCE_DIR" -type d); do
  LAST_MODIFIED_FILE="$DIR/.last_modified"

  # Get last modified time for the directory
  if [ -f "$LAST_MODIFIED_FILE" ]; then
    LAST_RUN=$(cat "$LAST_MODIFIED_FILE")
  else
    LAST_RUN=0
  fi

  YAML_FILES=()
  for FILE in "$DIR"/*.koreo; do
    [ -e "$FILE" ] || continue  # Skip if no .koreo files exist in directory
    FILE_MOD_TIME=$(stat -f %m "$FILE" 2>/dev/null || stat -c %Y "$FILE")
    if [ "$FILE_MOD_TIME" -le "$LAST_RUN" ]; then
      continue
    fi
    YAML_FILE="${FILE%.koreo}.yaml"
    cp "$FILE" "$YAML_FILE"
    echo "Converted $FILE to $YAML_FILE."
    YAML_FILES+=("$YAML_FILE")
  done

  # Apply all YAML files in the directory
  if [ ${#YAML_FILES[@]} -gt 0 ]; then
    kubectl apply -f "$DIR"
    if [ $? -eq 0 ]; then
      echo "Applied all YAML files in $DIR successfully."
    else
      echo "Error applying YAML files in $DIR."
      exit 1
    fi
    # Clean up YAML files
    rm "${YAML_FILES[@]}"
    echo "Cleaned up YAML files in $DIR."
  fi

  # Update last modified time for the directory
  date +%s > "$LAST_MODIFIED_FILE"
  echo "Updated last modified time for $DIR."

done

echo "All .koreo files processed and cleaned up successfully."

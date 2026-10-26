# AI Generated
#!/bin/bash

FOLDER_PATH="/path/to/folder"
TAR_FILE="/path/to/output.tar"
EXCLUDED_FILES="("file1.txt" "file2.txt" "file3.txt")

tar -cf "$TAR_FILE" --exclude=${EXCLUDED_FILES[0]}" --exclude=${EXCLUDED_FILES[1]}" --exclude=${EXCLUDED_FILES[2]}" "FOLDER_PATH"

#!/bin/bash

# Written by ChatGPT
# https://chat.openai.com/share/9170b2ba-7dca-40bd-9e53-9891303b33e4
# Check if the images/fronting directory exists, create it if not
if [ ! -d "./images/fronting" ]; then
  mkdir "./images/fronting"
fi

# Loop through each file that starts with fronting-logo-
for file in ./images/fronting-logo-*; do
  # Extract the file name without the directory and prefix
  filename=$(basename -- "$file")
  new_filename="${filename#fronting-logo-}"

  # Perform the move using git mv
  git mv "$file" "./images/fronting/$new_filename"
done

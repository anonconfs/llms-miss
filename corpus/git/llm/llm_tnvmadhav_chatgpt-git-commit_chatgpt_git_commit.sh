#!/bin/bash

# Change to the directory where your Git repository is located
cd /path/to/your/repo

# Get the Git diff and save it to a file
git diff > git_diff.txt

# Read the API key from an environment variable
API_KEY=$OPENAI_API_KEY

if [ -z "$API_KEY" ]; then
  echo "ERROR: OPENAI_API_KEY environment variable is not set"
  exit 1
fi

# Call the ChatGPT API to generate a commit message based on the diff
COMMIT_MSG=$(curl -X POST -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" -d '{"prompt": "Generate a commit message based on this Git diff:\n\n'"$(cat git_diff.txt)"'", "temperature": 0.5, "max_tokens": 30}' https://api.openai.com/v1/engines/davinci-codex/completions | jq -r '.choices[].text')

# Add and commit the changes with the generated commit message
git add .
git commit -m "$COMMIT_MSG"

echo "Changes committed with message: $COMMIT_MSG"
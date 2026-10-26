
#Script created by CHATGPT
#
 

#Make a branch for every single mutated repo, add all folder contents to it
#!/bin/bash

# Make sure you are on the main branch or a clean state



git checkout main
git pull origin main

# Loop through all directories in the repository
for dir in */; do
    if [ -d "$dir" ]; then
        branch_name=$(basename "$dir")
        echo "Processing directory: $branch_name"

        # Check if the branch exists
        if git show-ref --verify --quiet refs/heads/"$branch_name"; then
            # If the branch exists, switch to it
            echo "Branch $branch_name already exists. Switching to it."
            git checkout "$branch_name"
        else
            # If the branch doesn't exist, create it
            echo "Branch $branch_name does not exist. Creating it."
            git checkout -b "$branch_name"
        fi

        # Reset the working directory to only include the contents of the current folder
        git rm -rf --cached .  # Remove all tracked files (staging area)
        git add "$dir"  # Stage the contents of the current directory

        # Commit the folder's contents to the branch
        git commit -m "Add contents of $dir to $branch_name"

        # Push the new branch to the remote
        git push -u origin "$branch_name"

        # Switch back to the main branch
        git checkout main
    fi
done

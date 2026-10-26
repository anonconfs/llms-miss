#!/bin/bash
# Warp Session Recovery Script
# Generated: 2025-07-27T23:59:33.314998
# From database: test_data/warp_test.sqlite

echo '🚀 Starting Warp session recovery...'

echo '📁 Setting up project: /Users/test/other-project'
cd '/Users/test/other-project' 2>/dev/null || echo 'Warning: Directory not found'

git checkout develop 2>/dev/null || echo 'Warning: Branch develop not found'

echo '📁 Setting up project: /Users/test/my-project'
cd '/Users/test/my-project' 2>/dev/null || echo 'Warning: Directory not found'

git checkout main 2>/dev/null || echo 'Warning: Branch main not found'

echo '📋 Key commands from your session:'

# 2025-07-27 19:50:48 in /Users/test/other-project
# git push origin develop

# 2025-07-27 19:35:48 in /Users/test/other-project
# ls -la

# 2025-07-27 19:20:48 in /Users/test/other-project
# python script.py

# 2025-07-27 19:05:48 in /Users/test
# cd ../other-project

# 2025-07-27 18:45:48 in /Users/test/my-project
# git commit -m "fix tests"

# 2025-07-27 18:35:48 in /Users/test/my-project
# npm test
# ❌ Exit code: 1

# 2025-07-27 18:05:48 in /Users/test/my-project
# git status

echo '🤖 AI conversation context:'

# 2025-07-27 19:45:48 - claude-3
# Q: Explain this git push error and how to resolve it

# 2025-07-27 18:55:48 - gpt-4
# Q: Generate a Python script to process CSV files and output summary statistics

# 2025-07-27 18:25:48 - gpt-4
# Q: How do I fix this failing npm test?

echo '✅ Recovery context loaded!'
echo 'You can now continue your work where you left off.'

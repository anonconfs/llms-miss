#!/bin/bash
# written by ChatGPT

# Update package manager's package list
sudo pacman -Sy

# Install dependencies
sudo pacman -S --needed ghc alex happy pkg-config zlib

# render mermaid charts with pandoc
npm i -g mermaid-filter

#ghc: Glasgow Haskell Compiler, a compiler for the functional programming language Haskell. Pandoc is written in Haskell and requires the GHC to build and run.
#alex: A lexical analyzer generator for Haskell. It is used to generate the lexer for the Pandoc parser.
#happy: A parser generator for Haskell. It is used to generate the parser for the Pandoc parser.
#pkg-config: A tool for managing compile and link flags for libraries. It is used to detect and use the libraries that Pandoc depends on.
#zlib: A library for data compression. Pandoc uses it to read and write compressed files.

# Install pandoc
sudo pacman -S --needed pandoc

#If you want to use pandoc to convert files to PDF, you will need to install a LaTeX distribution. 

# Install TeX Live
sudo pacman -S --needed texlive-most
# Alternatively, install texlive-full

## Enable bash completion
bashrc="/home/$USER/.bashrc"
if [ -e "$bashrc" ]; then
    # grep: -q for quiet, -F for treating the string as fixed (dashes)
    grep -qF 'pandoc --bash-completion' "$bashrc"
    # return code 0 means 'found', 1 means 'not found'
    if [  $? -eq 1 ]; then
        echo "Appending bash completion configuration to $bashrc."

        # Append to .bashrc
        {
            echo "# Enable bash completion for pandoc (inserted by pandoc.sh install script)";
            echo 'if command -v pandoc > /dev/null; then' >> "$bashrc";
            # single quotes stop the $() expression from expanding, -e required to expand \t 
            echo -e '\teval "$(pandoc --bash-completion)"';
            echo 'fi'
        } >> "$bashrc"

    else
        echo "Bash completion already in $bashrc."
    fi
fi

# TODO: install custom themes and resources
# pandoc --version to get user directory
# create dir and link resources there, need to find that directory ~/.local/share/pandoc seems to cause errors
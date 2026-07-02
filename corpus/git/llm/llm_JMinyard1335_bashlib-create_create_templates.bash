#!/usr/bin/env bash
# Used to write out template files for the create command.

## SOURCE GUARD installer_templates.bash --------------------------------------------------
if [[ -v installer_templates_sourced ]]; then
    return 0
fi
installer_templates_sourced=1

installer_templates_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HOME"/.local/lib/style/bashlib_style.bash
## --------------------------------------------------------------------------------------

# write_tool_file <path> <tool_name>
# Used to create a new tool script template.
# file is created at path with the tool name as the filename.
# This file comes with a template header that helps properly source
# files from the lib and libexec folders. It also has a simple parser
# already set up with help and version.
# 
# Takes in the path to write the file and the tool name to create the file with.
# If no path is given it will default to the current directory. 
#If no tool name is given it will default to "mytool".
write_tool_file() {
    if [[ "$#" -ne 2 ]]; then
        print_error "create_write_tool_script: invalid argument count"
        return 1
    fi

    local path="${1:-.}"
    local tool_name="${2:-mytool}"
    local tool_identifier=""
    local tool_identifier="$(_create_tool_identifier "$tool_name")"

    echo -e "Creating tool file at \e[36m$path/$tool_name\e[0m..."
    cat > "$path/$tool_name"  <<-EOF
#!/usr/bin/env bash
# Description: A brief description of what the tool does.

## Sourcing Logic DO NOT EDIT ------------------------------------------------------
# This section is used to determine the location of the script
${tool_identifier}_script_name="\$(basename -- "\$0")"
${tool_identifier}_script_path="\$(realpath -- "\$0")"
${tool_identifier}_script_dir="\$(dirname -- "\$${tool_identifier}_script_path")"

# ${tool_identifier}_get_install_prefix <tool script directory>
# Used to echo the install path prefix.
# This is usually /usr/local or \$HOME/.local.
${tool_identifier}_get_install_prefix() {
    local tool_path="\${1:-}"

    if [[ "\$tool_path" = "\${HOME}/.local/bin" ]]; then
        echo "\$HOME/.local"
    elif [[ "\$tool_path" = "/usr/local/bin" ]]; then
        echo "/usr/local"
    elif [[ -d "\$tool_path/lib" ]]; then
        echo "\$tool_path"
    fi
}

# ${tool_identifier}_get_lib <install prefix> <tool>
# echos the proper lib path based on the install prefix and tool name.
# needed for proper sourcing of lib files based on where the tool is installed.
${tool_identifier}_get_lib() {
    local prefix="\${1:-}"
    local tool="\${2:-}"

    if [[ -z "\$prefix" ]]; then
        echo ""
        return 1
    fi

    if [[ "\$prefix" = "\$HOME/.local" || "\$prefix" = "/usr/local" ]]; then
        echo "\${prefix}/lib/\${tool}"
    else
        echo "\${prefix}/lib"
    fi
}

# ${tool_identifier}_get_libexec <install prefix> <tool>
# echos the proper libexec path based on the install prefix and tool name.
# needed for proper executing of libexec files based on where the tool is installed.
${tool_identifier}_get_libexec() {
    local prefix="\${1:-}"
    local tool="\${2:-}"

    if [[ -z "\$prefix" ]]; then
        echo ""
        return 1
    fi

    if [[ "\$prefix" = "\$HOME/.local" || "\$prefix" = "/usr/local" ]]; then
        echo "\${prefix}/libexec/\${tool}"
    else
        echo "\${prefix}/libexec"
    fi
}

# Grabs other project location info based on the script location.
# Needed to source the correct lib and libexec paths.
# sourcing can be done as follows
# source "${tool_identifier}_lib_dir/file to source"
${tool_identifier}_install_prefix="\$(${tool_identifier}_get_install_prefix "\$${tool_identifier}_script_dir")"
${tool_identifier}_libexec_dir="\$(${tool_identifier}_get_libexec "\$${tool_identifier}_install_prefix" "\$${tool_identifier}_script_name")"
${tool_identifier}_lib_dir="\$(${tool_identifier}_get_lib "\$${tool_identifier}_install_prefix" "\$${tool_identifier}_script_name")"
## End of Sourcing Logic -----------------------------------------------------------------

${tool_identifier}_version="0.1.0"

_${tool_identifier}_usage() {
    echo "Usage: ${tool_identifier} [options]"
    echo
    echo "Consider using bashlib-style for a stylish help message."
    echo "https://github.com/JMinyard1335/bashlib-style"
    echo "its as easy as adding:"
    echo style="https://github.com/JMinyard1335/bashlib-style"'
    echo "to your dependency section of the tool.toml file."
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message and exit"
    echo "  -v, --version   Show the version number and exit"
}

${tool_identifier}_parse() {
    [[ "\$#" -eq 0 ]] && { echo "must give some options">&2 ; _${tool_identifier}_usage ; exit 1; }
    while [[ "\$#" -gt 0 ]]; do
        case "\$1" in
            -h|--help)
                _${tool_identifier}_usage
                exit 0
                ;;
            -v|--version)
                echo "$tool_name version \$${tool_identifier}_version"
                exit 0
                ;;
            *)
                echo "Unknown option: \$1" >&2
                _${tool_identifier}_usage
                exit 1
                ;;
        esac
        shift
    done
}


# Put any tool specific setup code here
${tool_identifier}_main() {
    ${tool_identifier}_parse "\$@"
}


# Main is only called if this script is run directly, if it is sourced then main is not called.
if [[ "\${BASH_SOURCE[0]}" == "\${0}" ]]; then
    ${tool_identifier}_main "\$@"
fi

EOF

}

# write_exe_file <path> <file_name>
# Used to create a exec file found in
# the libexec dir.
write_exec_file() {
    if [[ "$#" -ne 2 ]]; then
        print_error "write_lib_file: invalid argument count"
        return 1
    fi
    
    local path="${1:-.}"
    local file_name="${2:-'mytool'}"
    local tool_identifier=""
    local tool_identifier="$(_create_tool_identifier "$file_name")"
    local full_path="$path/$file_name"

    cat > "$full_path"<<-EOF
#!/usr/bin/env bash

## Sourcing Logic DO NOT EDIT --------------------------------------------------
# This section is used to determine the location of the script
# This section is used to determine the location of the script
${tool_identifier}_tool_name=""
${tool_identifier}_script_path="\$(realpath -- "\$0")"
${tool_identifier}_script_dir="\$(dirname -- "\$${tool_identifier}_script_path")"

# ${tool_identifier}_get_install_prefix <tool script directory>
# Used to echo the install path prefix.
# This is usually /usr/local or \$HOME/.local.
${tool_identifier}_get_install_prefix() {
    local tool_path="\${1:-}"

    if [[ "\$tool_path" = "\${HOME}/.local/libexec/\${${tool_identifier}_tool_name}" ]]; then
        echo "\$HOME/.local"
    elif [[ "\$tool_path" = "/usr/local/libexec/\${${tool_identifier}_tool_name}" ]]; then
        echo "/usr/local"
    elif [[ -d "\$tool_path/../lib" ]]; then
        echo "\${tool_path}/.."
    fi
}

# ${tool_identifier}_get_lib <install prefix> <tool>
# echos the proper lib path based on the install prefix and tool name.
# needed for proper sourcing of lib files based on where the tool is installed.
${tool_identifier}_get_lib() {
    local prefix="\${1:-}"
    local tool="\${2:-}"

    if [[ -z "\$prefix" ]]; then
        echo ""
        return 1
    fi

    if [[ "\$prefix" = "\$HOME/.local" || "\$prefix" = "/usr/local" ]]; then
        echo "\${prefix}/lib/\${tool}"
    else
        echo "\${prefix}/lib"
    fi
}

${tool_identifier}_install_prefix="\$(${tool_identifier}_get_install_prefix "\$${tool_identifier}_script_dir")"
${tool_identifier}_lib_dir="\$(${tool_identifier}_get_lib "\$${tool_identifier}_install_prefix" "\$${tool_identifier}_tool_name")"
# End of source section --------------------------------------------------------

${tool_identifier}_version="0.1.0"

_${tool_identifier}_usage() {
    echo "Usage: ${tool_identifier} [options]"
    echo
    echo "Consider using bashlib-style for a stylish help message."
    echo "https://github.com/JMinyard1335/bashlib-style"
    echo "its as easy as adding:"
    echo 'style="https://github.com/JMinyard1335/bashlib-style"'
    echo "to your dependency section of the tool.toml file."
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message and exit"
    echo "  -v, --version   Show the version number and exit"
}

${tool_identifier}_parse() {
    [[ "\$#" -eq 0 ]] && { echo "must give some options">&2 ; _${tool_identifier}_usage ; exit 1; }
    while [[ "\$#" -gt 0 ]]; do
        case "\$1" in
            -h|--help)
                _${tool_identifier}_usage
                exit 0
                ;;
            -v|--version)
                echo "$tool_name version \$${tool_identifier}_version"
                exit 0
                ;;
            *)
                echo "Unknown option: \$1" >&2
                _${tool_identifier}_usage
                exit 1
                ;;
        esac
        shift
    done
}


# Put any tool specific setup code here
${tool_identifier}_main() {
    ${tool_identifier}_parse "\$@"
}


# Main is only called if this script is run directly, if it is sourced then main is not called.
if [[ "\${BASH_SOURCE[0]}" == "\${0}" ]]; then
    ${tool_identifier}_main "\$@"
fi

EOF

    chmod +x "$full_path"
    
}

# write_lib_file <path> <file_name>
# Used to create a lib file found in lib
write_lib_file() {
    if [[ "$#" -ne 2 ]]; then
        print_error "write_lib_file: invalid argument count"
        return 1
    fi

    local path="${1:-.}"
    local file_name="${2:-'mytool'}"
    local tool_identifier=""
    local tool_identifier="$(_create_tool_identifier "$file_name")"
    local file_ext="bash"
    local full_path="$path/$file_name.$file_ext"

    cat > "$full_path" <<-EOF
#!/usr/bin/env bash
# This is a lib file for $file_name. Put any functions that you want to use in the tool script here.


## SOURCE GUARD DO NOT REMOVE ${file_name}.bash -----------------------------------------
if [[ -v ${tool_identifier}_lib_sourced ]]; then
    return 0
fi
${tool_identifier}_lib_sourced=1
## --------------------------------------------------------------------------------------

#Use this to source other lib files. the current location of this script.
# source ${tool_identifier}_lib_dir/<other file>
# source ${tool_identifier}_lib_dir/../<other dir in lib>
${tool_identifier}_lib_dir="\$(cd -- "\$(dirname -- "\${BASH_SOURCE[0]}")" && pwd)"

EOF
}

# write_readme <path> <tool_name> <repo>
write_readme() {
    if [[ "$#" -ne 3 ]]; then
        print_error "write_readme: invalid argument count"
        return 1
    fi

    local path="${1:-.}"
    local tool_name="${2:-my_tool}"
    local repo="${3:-path to your repo}"
    local file_name='README'
    local file_ext="md"
    local full_path="$path/$file_name.$file_ext"

    echo -e "Creating README file at \e[36m$full_path\e[0m..."
    cat > "$full_path" <<-EOF
# ${tool_name}

Created by bashlib installer. Place a description of your project here.

## Installation

Clone the repository and install the tool:

\`\`\`bash
git clone "${repo}"
cd ${tool_name}
chmod +x ${tool_name}
./${tool_name} --help
\`\`\`

## Usage

\`\`\`bash
./${tool_name} --help
\`\`\`

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.
EOF
}

# write_gitignore <path>
write_gitignore() {
    if [[ "$#" -ne 1 ]]; then
        print_error "write_gitignore: invalid argument count"
        return 1
    fi

    local path="${1:-.}"
    local full_path="$path/.gitignore"

    echo -e "Creating .gitignore file at \e[36m$full_path\e[0m..."
    cat > "$full_path" <<EOF
# Bash common ignores
*~


# Build artifacts
build/
dist/

# IDE
.vscode/
.idea/
*.iml
EOF
}

# write_tool_toml <path> <project_name> <tool_name> <author> <repo> <description>
write_tool_toml() {
    if [[ "$#" -ne 6 ]]; then
        print_error "write_tool_toml: invalid argument count"
        return 1
    fi

    local path="${1:-.}"
    local project_name="${2:-my_project}"
    local tool_name="${3:-my_tool}"
    local author="${4:-Author Name}"
    local repo="${5:-https://github.com/user/repo}"
    local description="${6:-A brief description of the project.}"
    local full_path="$path/tool.toml"

    echo -e "Creating tool.toml file at \e[36m$full_path\e[0m..."
    cat > "$full_path" <<-EOF
[project]
tool = "${tool_name}"
project = "${project_name}"
version = "0.1.0"
author = "${author}"
repo = "${repo}"
description = "${description}"

[directories]
lib = "lib"
libexec = "libexec"
man = "man"

[dependencies]
EOF
}


# write_contributing_md <path> <repo> <project_name> <tool_name>
write_contributing_md() {
    local path="" repo="" p_name="" tool_name="" full_path=""
    if [[ "$#" -ne 4 ]]; then
	print_error "write_contributing_md: invalid argument count"
	return 1
    fi

    path="${1:-.}"
    repo="${2:-}"
    p_name="${3:-my_project}"
    t_name="${4:-my_tool}"
    full_path="${path}/CONTRIBUTING.md"
    
    print_log "creating CONTRIBUTING.md at \e[36m${full_path}\e[0m"
    cat > "$full_path"<<-EOF
# Contributing to ${p_name}

Thanks for your interest in improving \`${p_name}\`.

## Ways To Contribute

- Report bugs and unexpected behavior.
- Suggest or implement install/remove/update/create workflow improvements.
- Improve docs and usage examples.
- Add tests and edge-case coverage.

## Development Setup

\`\`\`bash
git clone "${repo}"
cd ${p_name}
chmod +x ./${t_name}
./${t_name} help
\`\`\`

## Project Layout

- \`${t_name}\`: top-level command dispatcher.
- \`lib/\`: sourceable library files.
- \`lib/internal/\`: ${t_name} internals and shared helpers.
- \`libexec/\`: subcommand executables.
- \`test/\`: fail-first test suite and test helpers.

## Coding Guidelines

- Keep scripts Bash-focused and portable.
- Preserve existing naming patterns (\`${p_name}_*\`, \`${t_name}_*\`, \`_${t_name}_*\`).
- Keep scripts you execute extensionless; scripts you source should be \`*.bash\`.
- Prefer small, clear functions.
- Quote variables unless word splitting is explicitly needed.
- Keep CLI help text and docs in sync with behavior.

## Testing Checklist

Before opening a pull request, run:

\`\`\`bash
./${t_name} help
./test/test_all.bash
\`\`\`

If your change affects parsing or error handling, test at least one invalid input path.

## Pull Request Notes

- Keep PRs focused (one feature/fix per PR when possible).
- Explain why the change is needed.
- List behavior changes and any CLI output changes.
- Update \`README.md\`, \`INSTALL.md\`, and command help text when behavior or setup changes.
- For Major Changes and New Features add a Section to the [change log](docs/CHANGELOG.md).

## Commit Message Suggestions

Use short, imperative commit messages, for example:

- \`fix install arg parsing\`
- \`add install guide\`
- \`improve update error output\`

## AI-Assisted Contributions

AI tools are welcome for drafting code, docs, tests, and refactors.
Contributors remain fully responsible for all submitted changes.

### Requirements

- Verify behavior manually before opening a PR.
- Run the project checklist:
	- \`./${t_name} help\`
	- \`./test/test_all.bash\`
- Ensure generated code matches project conventions (\`${p_name}_*\`, \`${t_name}_*\`, extensionless executables, \`*.bash\` source files).
- Do not include secrets, tokens, private keys, or private/internal code in prompts.
- Do not copy copyrighted or proprietary code verbatim from external sources.
- Keep PRs understandable: explain what changed and why, not just "AI generated this."
- Update \`README.md\` and \`INSTALL.md\` when behavior or setup changes.
- If AI was used significantly, briefly disclose it in the PR description (for example: "AI-assisted drafting, manually reviewed and tested").

### Not Acceptable

- Submitting unreviewed AI output.
- Large AI-generated changes without tests or explanation.
- Output that adds unnecessary complexity or breaks existing UX/help text.

EOF

}

## Helpers --------------------------------------------------------------------------------

# _create_tool_identifier <tool name>
# Used to create a valid bash identifier from the tool name.
_create_tool_identifier() {
    local value="${1:-tool}"

    value="${value//[^A-Za-z0-9_]/_}"
    [[ "$value" =~ ^[0-9] ]] && value="_$value"
    [[ -z "$value" ]] && value="tool"

    printf '%s' "$value"
}

#!/usr/bin/env bash
# vim:tw=80:ts=4:sw=4:ai:et:ff=unix:fenc=utf-8:et:fixeol:eol:fdm=marker:fdl=0:fen:
#
# manage.sh - Script to manage the project.
#

# Load shell helpers, define constants, install this script. {{{
shell_helpers="$HOME/bin/.rc.common"
. $shell_helpers


# Define file constants.
this_file="$(mm_file_path "$0")"
this_file_directory="$(mm_dir_path "$this_file")"


# Check if this file is installed to $MCRA_BIN (default: $HOME/bin) and if not,
# ask the user to install it.
if [ ! -f "$MCRA_BIN/cli" ]; then
    install_this_file() {
        local should_install_this="no"

        echo "This file is not installed. Install? (will symlink this script to $MCRA_BIN/cli)"
        read -p 'y/N ' should_install_this

        if [ "$should_install_this" = "y" ]; then
            echo 'Yes! Installing...'
            if [ ! -d "$MCRA_BIN" ]; then
                mkdir "$MCRA_BIN" || fatal "Failed to create '$MCRA_BIN'"
            fi

            ln -s "$this_file" "$MCRA_BIN/cli" || fatal 'Symlink failed. Check output'

            echo 'Done!'
        else
            echo 'Not installing.'
        fi
    }

    install_this_file
fi
# }}}


# All commands should be add here, along with description of how to use them.
usage() { #{{{
    mm_trim "
    Usage: cli [command]

    Commands
        - help: Show this message.
        - edit: Edit this file using $EDITOR (alias: e, -e, --edit).
        - code: Edit this file using VSCode
        - cron: Open crontab file.
        - commitlint: Setup commit linting with husky and conventional commits.
        - pandoc: Print a pandoc man example command, with groff.
        - common: Edit shell helpers.
        - commonp: Edit personal shell helpers.
        - dartjs: Compile dart to js with level 2 of optimizations.
        - dotnet (alias: dn):
            Provides a number of helpers for when developing using FSharp. Use
            the 'help' command to see what is available.
        - compare-compilations: Compare the binary size of hello world programs.
        - install-protoc:
            Install protocol buffers compiler. For details and more information,
            see the https://grpc.io/docs/protoc-installation/ page.
        - json-yaml:
            Convert a json file into yaml and vice versa, depending on the input
            and output file extensions. Require Deno.
        - example-inline-dart-program:
            Show how to create an inline dart program. This works for any
            programming language.
        - example-inline-python-script:
        - install-python-typings:
            Install mypy, to check Python files that use type hints. More
            details in their GitHub page:
                https://github.com/python/mypy
        - mypy: Run Python typechecker.
        - tsconfig: Creates a new tsconfig files in the current directory.
        - node-save-prefix:
            Saves npm/pnpm dependencies using exact version instead of variable
            versions (depending on ^ or ~).
        - add-tailwind: Adds TailwindCSS and DaisyUI to a project.
        - add-js-essentials: Adds essential JavaScript packages.
        - new:
            Expects a second argument, with the name of the file that should be
            created. Templates are copied from the 'cli/templates'. To See all
            available templates, run 'cli new help'.
        - eslint-prettier:
            Configure eslint and prettier in a new node project.
        - install-essentials:
            Install essential packages for a new OS installation.
            Run 'cli install-essentials help' for more information.
        - sri-hash:
            Generates an SRI hash for a file or url. For more details, see here:
            https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity#tools_for_generating_sri_hashes
        - curl:
            Uses 'curl' with predefined options that I won't remember:
                curl -LO URL_HERE
            -L: follow redirects
            -O: save the retrieved file with the same name as in the server
        - to-json-string:
            Converts the input to a json string.
        - NEXT COMMAND HERE:
            This is a placeholder command to allow me to search for 'next' and
            get here. Add new commands before this one.
    " 4

} #}}}


if [ $# -eq 0 ]; then
    usage
    echo
    fatal 'Invalid option'
fi



# Parses cli arguments and run the selected commands. Note that all functions
# should be defined inside the command case statement, to avoid mixing one
# command with the other.
main() {
    local editor="${EDITOR:-vi}"

    # Process command line arguments.
    while [ $# -gt 0 ]; do
        case "$1" in
            help|""|-h|--help) #{{{
                usage
                ;; #}}}
            e|edit|-e|--edit) #{{{
                (cd $this_file_directory && $editor $this_file)
                ;; #}}}
            code) #{{{
                (cd $this_file_directory && code .)
                ;; #}}}
            cron) #{{{
                crontab -e
                ;; #}}}
            commitlint) #{{{
                echo 'See full commitlint docs here:'
                echo '  https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional'
                echo

                if [ -f "./package.json" ]; then
                    echo 'Folder already contains a package.json file. Skipping npm init.'
                else
                    npm init -y
                fi

                echo 'Installing commitlint and husky as development dependencies...'
                npm install --save-dev @commitlint/{cli,config-conventional} husky

                echo 'Creating commitlint config and husky hooks...'
                echo "export default {extends: ['@commitlint/config-conventional']};" > commitlint.config.js
                npx husky init
                echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg

                echo 'Run the following, to test your setup if you already have commited something:'
                echo '  npx commitlint --from HEAD~1 --to HEAD --verbose'
                echo
                ;; #}}}
            pandoc) #{{{
                mm_trim '
                    To create a manpage, check out the code below or follow the
                    full tutorial here:

                        https://gpanders.com/blog/write-your-own-man-pages/

                    pandoc --standalone \
                        --from markdown \
                        --to man \
                        --metadata title="pandoc example" \
                        --metadata author="marcelo" \
                        --metadata section="the section name" \
                        --metadata date="$(date +%F_%T -r stuff.md)" \
                        stuff.md | groff -T utf8 -man | nvim "+Man!"
                ' 12
                ;; #}}}
            common) #{{{
                (cd "$(mm_dir_path $shell_helpers)" && $editor $shell_helpers)
                ;; #}}}
            commonp) #{{{
                local filename="$MCRA_BIN/commonp.sh"
                (cd "$(mm_dir_path $filename)" && $editor $filename)
                ;; #}}}
            dart) #{{{
                local filename="${3:-main}"

                case "$2" in

                    help|-h|--help)

                        mm_trim '
                            Usage:
                                cli dart [options, default=exe] [filename, default=main, .dart is implied]

                            Options:
                                - exe: dart compile exe
                                - js: dart compile js: default optimizations
                                - jsopt: dart compile js -O2: level 2 optimizations, which are still safe, but smaller
                        ' 24

                        return 1

                        ;;

                    js)
                        dart compile js -o $filename.js $filename.dart
                        ;;
                    jsopt)
                        dart compile js ${3:--O2} -o $filename.js $filename.dart
                        ;;
                    exe|*)
                        dart compile exe -o $filename.exe $filename.dart
                        ;;
                esac
                return $?
                ;; #}}}
            dotnet|dn) #{{{
                local cmd="$2"
                usage() {
                    mm_trim '
                        Usage: cli dotnet[dn] <command>

                        Commands:
                            tools:
                                Creates a new manifest and install some
                                frequently used packages (check the command for
                                more details about the packages).
                            neovim (nvim|vim|vi):
                                Lists all steps that we must follow to get
                                (Neo)Vim to provide autocomplete for FSharp.
                            publish:
                                Creates a self contained release binary of a
                                dotnet project.
                            new:
                                Creates a new FSharp project. Uses $PROJ_NAME
                                to set the project name and $PROJ_TYPE to choose
                                between console or classlib.
                            solution (s|sol):
                                Lists all commands used to manage solutions.
                            libs-node (node):
                                Install Fable libs essential for Node
                                development.
                            libs-browser (browser):
                                Install Fable libs essential for browser
                                development.
                            help:
                                Shows this message.
                    ' 20
                }
                if [ -z "$cmd" ]; then
                    usage
                    fatal 'Error: no command provided.'
                fi

                case $cmd in
                    tools) #{{{

                        # Initialize local configuration file.
                        dotnet new tool-manifest

                        # Dependency manager.
                        dotnet tool install paket
                        dotnet tool restore

                        # Task runner. (Not using, so commented out.)
                        # dotnet tool install fake-cli

                        # Formatter.
                        dotnet tool install fantomas

                        # Autocomplete.
                        dotnet tool install fsautocomplete

                        # F# to JavaScript compiler.
                        dotnet tool install fable

                        # F# JavaScript npm package manager.
                        # (Currently, I prefer to do this myself.
                        # dotnet tool install femto

                        # Creates a .gitignore with common F# stuff.
                        dotnet new gitignore

                        ;; #}}}
                    neovim|nvim|vim|vi) #{{{
                        # Uncomment this block or do what it suggests manually to
                        # enable vim autocomplete for fsharp files with paket.
                        mm_trim '
                        To use FSharp with (Neo)Vim, install the Ionide vim
                        plugin from https://github.com/ionide/Ionide-vim.

                        You will need to install `fsautocomplete`, either
                        locally to the project or globally. When installed
                        locally, you need to update Vim settings to use the project tool, as described
                        in its documentation:

                            https://github.com/ionide/Ionide-vim?tab=readme-ov-file#set-the-path-to-fsac

                        For `fsautocomplete` to recognize `paket` as a directive in `#r`, you also need
                        to install the `FSharp.DependencyManager.Paket.dll` and copy/symlink it to `fsautocomplete`.
                        To do that, I followed these steps:

                        1) Install `FSharp.DependencyManager.Paket`:
                            dotnet add package FSharp.DependencyManager.Paket
                            or
                            paket add FSharp.DependencyManager.Paket

                        2) Find the full path for
                        `FSharp.DependencyManager.Paket.dll` in ~/.nuget. Mine:

                            ~/.nuget/packages/fsharp.dependencymanager.paket/8.0.3/lib/netstandard2.0/FSharp.DependencyManager.Paket.dll

                        3) Find the full path of the `fsautocomplete` directory
                        in ~/.nuget. Mine:

                            ~/.nuget/packages/fsautocomplete/0.73.2/tools/net8.0/any/

                        4) Symlink 2 to 3. (You can copy, instead, but I like to
                        symlink.)

                        ln -s \
                            $HOME/.nuget/packages/fsharp.dependencymanager.paket/8.0.3/lib/netstandard2.0/FSharp.DependencyManager.Paket.dll \
                            $HOME/.nuget/packages/fsautocomplete/0.73.2/tools/net8.0/any/

                        I have not tested this with a global installation of
                        `fsautocomplete`.
                        ' 24
                        ;; #}}}
                    publish) #{{{
                        dotnet publish -c Release -p:PublishSingleFile=true -p:PublishTrimmed=true --self-contained true
                        ;; #}}}
                    new) #{{{
                        local proj_type="${PROJ_TYPE:-console}"
                        local proj_name="${PROJ_NAME:-fsharp-${proj_type}-project}"
                        local cli_cmd="cli dotnet new"

                        if [ "$3" != "-y" ]; then
                            mm_trim "
                            Usage: $cli_cmd -y

                            This command will create a new project (and folder)
                            in the current directory (or reuse one, if it exists
                            with the same path). Current configuration:

                                Project name: $proj_name (\$PROJ_NAME)
                                Project type: $proj_type (\$PROJ_TYPE)

                            You can change that by providing those envs before
                            calling this script. For example:

                                \$PROJ_NAME=my-project $cli_cmd -y
                            " 28
                            fatal "'-y' not provided. Aborting."
                        fi

                        if [ ! -d "$proj_name" ]; then
                            echo "Creating directory '$proj_name'..."
                            mkdir -p "$proj_name" || fatal "Failed to create directory: $proj_name"
                            echo 'Done!'
                        fi

                        cd "$proj_name" || fatal "Failte to enter path: $proj_name"

                        echo "Creating a new F# $proj_type project..."
                        if [ "$proj_type" = "console" ]; then
                            dotnet new console -lang 'F#' || fatal 'failed'
                        elif [ "$proj_type" = "classlib" ]; then
                            dotnet new classlib -lang "F#" || fatal 'failed'
                        else
                            fatal "Invalid project type: $proj_type"
                        fi

                        echo 'Done!'
                        return $?

                        ;; #}}}
                    solution|sol|s) #{{{

                        mm_trim '
                            Use the following commands to manage an FSharp multi-project solution.
                            This is an example iteration:

                            # Create a solution (multi-project project):
                            dotnet new sln -o <solution name>

                            # Create projects inside the solution. Console project:
                            dotnet new console -lang "F#" -o src/App

                            # Create a build console project too:
                            dotnet new console -lang "F#" -o src/Build

                            # Library project:
                            dotnet new classlib -lang "F#" -o src/Library

                            # Add internal projects to the solution (you can also remove, if
                            # necessary, using the `remove` command):
                            dotnet sln add src/App/App.fsproj
                            dotnet sln add src/Library/Library.fsproj
                            dotnet sln add src/Build/Build.fsproj

                            # Add one project as a reference in the other, for example, if the App
                            # uses the Library:
                            dotnet add src/App/App.fsproj reference src/Library/Library.fsproj

                            # Example build script, to use the Build project as a build tool:

                                # Linux, in a .sh file:
                                dotnet run --project ./build/Femto.Build.fsproj -- $1

                                # Windows, in a .cmd file:
                                dotnet run --project ./build/Femto.Build.fsproj -- %1

                        ' 24

                        ;; #}}}
                    libs-node|node) #{{{
                        dotnet paket add Fable.Core
                        dotnet paket add Thoth.Json

                        return $?
                        ;; #}}}
                    libs-browser|browser) #{{{
                        dotnet paket add Fable.Browser.Dom
                        dotnet paket add Fable.Elmish.React
                        dotnet paket add Thoth.Json

                        return $?
                        ;; #}}}
                    help) #{{{
                        usage
                        ;; #}}}
                    *) #{{{
                        usage
                        fatal "Invalid command command: $cmd"
                        ;; #}}}
                esac

                return $?

                ;; #}}}
            compare-compilations) #{{{
                mm_trim '

                    Creating the same program that would simply print "hello
                    world" to the console yields very different size of binaries depending on the tooling that is used.

                    Examples:

                        28jul24/13h12:

                            - TypeScript + Deno: 80M
                            - Dart: 5.4M
                            - F#:
                                - PublishTrimmed=false: 68M
                                - PublishTrimmed=true:  14M
                ' 12
                return 0
                ;; #}}}
            install-protoc) #{{{
                fatal_extra() {
                    echo 'Updated instructions here:'
                    echo '  https://grpc.io/docs/protoc-installation/'
                    fatal "$1"
                }

                local pb_releases='https://github.com/protocolbuffers/protobuf/releases'
                local protoc_version='27.2'
                local protoc_zip_filename="protoc-$protoc_version-linux-x86_64.zip"
                local protoc_zip_path="$pb_releases/download/v$protoc_version/$protoc_zip_filename"
                local protoc_local_dir="$HOME/bin/binaries/protoc/v$protoc_version"
                if [ ! -d "$protoc_local_dir" ]; then
                    mkdir -p "$protoc_local_dir"
                fi

                curl -LO "$protoc_zip_path" || fatal_extra 'Failed to download protoc zip'
                unzip $protoc_zip_filename -d $protoc_local_dir || fatal_extra 'Failed to extract protoc zip'

                echo 'Symlinking to a location present in PATH...'
                ln -s "$protoc_local_dir/bin/protoc" "$HOME/bin/protoc" \
                    || fatal_extra "Symlink '$protoc_local_dir/bin/protoc' to a location in your PATH"

                return 0
                ;; #}}}
            install-grpc-dart) #{{{
                echo 'See details here:'
                echo '  https://grpc.io/docs/languages/dart/quickstart/'
                return 1
                ;; #}}}
            json-yaml) #{{{
                if [ -z "$2" ] || [ -z "$3" ]
                then
                    fatal 'Usage: json-yaml <file 1> <file 2> (files should be .json or .yaml)'
                fi

                # File paths.
                local json_input="$2"
                local yaml_output="$3"

                deno run --allow-read --allow-write "$this_file_directory/scripts/json-to-yaml.ts"  $json_input  "$yaml_output"

                return $?
                ;; #}}}
            example-inline-dart-program) #{{{
                # See the help for details.

                # I'm using 'EOF' to avoid variable substitution in the heredoc.
                local file_to_run="$(mktemp)" && cat <<'EOF' > $file_to_run && dart run $file_to_run
import "dart:io";

void main() async {
    var dir = Directory('.');

    var dirList = dir.list();
    await for (final FileSystemEntity f in dirList) {
        print(f.path);
    }

    // // If error handling is desirable, wrap the code in a try-catch block, as
    // // demonstrated below.
    // try {
    //     var dirList = dir.list();
    //     await for (final FileSystemEntity f in dirList) {
    //         if (f is File) {
    //             print('Found file ${f.path}');
    //         } else if (f is Directory) {
    //             print('Found dir ${f.path}');
    //         }
    //     }
    // } catch (e) {
    //     print(e.toString());
    // }
}

EOF
                ;; #}}}
            example-inline-python-script) #{{{
                local file_to_run="$(mktemp)" && cat <<'EOF' > $file_to_run && python3 $file_to_run
import os

def main():
    cwd = os.getcwd()
    fs = os.listdir(cwd)
    print('\n'.join(fs))

    # # One line version.
    # [print(f) for f in sorted(os.listdir(os.getcwd()))]

    # # If error handling is desirable, wrap the code in a try-catch block, as
    # # demonstrated below.
    # try:
    #     for f in fs:
    #         print(f)
    # except Exception as e:
    #     print(e)

if __name__ == '__main__':
    main()
EOF
                ;; #}}}
            install-python-typings) #{{{

                # The -U is for `upgrade`.
                python3 -m pip install -U mypy || fatal 'Failed to install mypy'
                return 0
                ;; #}}}
            mypy) #{{{

                case "$2" in
                    *.py)
                        mypy $2
                        return $?
                        ;;
                    *)
                        fatal '\nERROR. Please, provide a Python file.'
                        ;;
                esac

                ;; #}}}
            tsconfig) #{{{
                npx --package=typescript@5.5.4 -- tsc --init
                return $?
                ;; #}}}
            node-save-prefix) #{{{
                npm config set save-prefix=''
                pnpm config set save-prefix=''
                return $?
                ;; #}}}
            add-tailwind) #{{{
                "$this_file_directory/scripts/add-tailwind.js"
                return $?
                ;; #}}}
            add-js-essentials) #{{{
                "$this_file_directory/scripts/add-js-essentials.js"
                return $?
                ;; #}}}
            integrate-prettier-with-eslint) #{{{
                # Install required packages.
                npm i -D prettier-plugin-tailwindcss eslint-config-prettier eslint-config-google prettier @trivago/prettier-plugin-sort-imports

                mm_trim "
                    Add \"google\" to the .eslintrc \"extends\" property. Its
                    priority is defined by its order in the array. Choose as you
                    prefer.

                    Then add \"prettier\" in the \"plugins\". Same idea applies.
                " 16

                mm_trim '
                    Finally, add the following "prettier" object in the
                    package.json:

                        "prettier": {
                            "importOrder": [
                                "^(node|npm):",
                                "^[p]react",
                                "<THIRD_PARTY_MODULES>",
                                "^@/(.*)$",
                                "^[./]"
                            ],
                            "importOrderSeparation": true,
                            "importOrderSortSpecifiers": true,
                            "plugins": [
                                "prettier-plugin-tailwindcss",
                                "@trivago/prettier-plugin-sort-imports"
                            ]
                        }
                ' 16

                return $?

                ;; #}}}
            new) #{{{
                local templates_dir="$this_file_directory/templates"
                local template=''

                case "$2" in
                    gitattributes|gita)
                        template='.gitattributes'
                        ;;
                    gitignore|giti)
                        template='.gitignore'
                        ;;
                    editorconfig|ec)
                        template='.editorconfig'
                        ;;
                    eslintrc|eslint)
                        template='eslint.config.js'
                        ;;
                    prettierrc|prettier)
                        template='prettier.config.js'
                        ;;
                    changelog|cl)
                        template='CHANGELOG.md'
                        ;;
                    license|lic)
                        template='LICENSE.txt'
                        file="$templates_dir/$template"
                        echo 'Creating a new LICENSE.txt file in the current directory...'
                        cat $file | sed -E -e `echo "s/YYYY/$(date '+%Y')/g"` > $template
                        echo 'First 10 lines:'
                        echo ''
                        cat $template | head -n10 | sed -E -e 's/^/  |  /'
                        return $?
                        ;;
                    license-apache|lic-apache|apache)
                        template='LICENSE-apache.txt'
                        ;;
                    tsconfig|tsc)
                        template='tsconfig.json'
                        ;;
                    dev)
                        template='dev'
                        ;;
                    manifest)
                        cp "$templates_dir/manifest.json" "manifest.json"

                        mm_trim '
                        Create the folders listed below, either directly (with
                        mkdir) or using a generator for your favourite frontend
                        framework. For example, to use Svelte and TypeScript for
                        the popup page:

                            mkdir -p src/pages/popup
                            cd src/pages/popup
                            pnpm create vite . --template svelte-ts

                        You can run the command without the --template argument
                        to create interactively, choosing the options:

                            pnpm create vite .

                        Available templates as of 17nov24 (see
                        https://vite.dev/guide for up-to-date options):

                          vanilla, vanilla-ts, vue, vue-ts, react, react-ts,
                          react-swc, react-swc-ts, preact, preact-ts, lit,
                          lit-ts, svelte, svelte-ts, solid, solid-ts, qwik,
                          qwik-ts

                        Folders you most likely will need:

                            Pages:

                                ./src/pages/popup
                                ./src/pages/options

                            Service worker and content script:

                                ./src/service-worker
                                ./src/content-script

                            Assets (images):

                                ./src/assets/images

                            Releases:

                                ./release (current release, for local testing)
                                ./releases (each release zip, to upload in CWS)

                            Executable scripts:

                                ./bin

                        INFO: This script created a ./manifest.json for you.

                        ' 24

                        # echo 'Creating folders...\nPages: ./src/pages/{popup|options}' \
                        #     && mkdir -p src/pages/popup \
                        #     && mkdir src/pages/options \
                        #     && echo 'Done!\nService worker: ./src/service-worker' \
                        #     && mkdir src/content-script \
                        #     && echo 'Done!\nContent script: ./src/content-script' \
                        #     && mkdir src/service-worker \
                        #     && echo 'Done!\nAssets: ./src/assets/images' \
                        #     && mkdir -p src/assets/images \
                        #     && echo 'Done!\nFor releases: ./{release|releases}' \
                        #     && mkdir release \
                        #     && mkdir releases \
                        #     && echo 'Done!\nFor executable scripts: ./bin' \
                        #     && mkdir bin \
                        #     && echo 'Done!\n\nYour code structure is ready, now you can go coding! Enjoy!!'

                        return $?

                        ;;
                    ws|pnpm-workspace)
                        template='pnpm-workspace.yaml'
                        ;;

                    monorepo|mr)

                        echo "prepare which files for a monorepo, as there's no need for eslint/prettier stuff, etc"

                        return 1

                        ;;
                    package|pkg)
                        cp "$templates_dir/package.json" "package.json"
                        cp "$templates_dir/prettier.config.js" "prettier.config.js"
                        cp "$templates_dir/eslint.config.js" "eslint.config.js"
                        cp "$templates_dir/.editorconfig" ".editorconfig"

                        return $?
                        ;;
                    package-c|pkg-c)
                        # TODO: automatically update package.json with latest
                        # version from pnpm-workspace.yaml's catalog.
                        cp "$templates_dir/package-catalog.json" "package.json"
                        cp "$templates_dir/pnpm-workspace.yaml" "pnpm-workspace.yaml"
                        cp "$templates_dir/prettier.config.js" "prettier.config.js"
                        cp "$templates_dir/eslint.config.js" "eslint.config.js"
                        cp "$templates_dir/.editorconfig" ".editorconfig"

                        return $?
                        ;;
                    package-tw|pkg-tw)
                        cp "$templates_dir/package-tw.json" "package.json"
                        cp "$templates_dir/prettier-tw.config.js" "prettier.config.js"
                        cp "$templates_dir/tailwind+twTypography+daisyui.js" "tailwind.config.js"
                        cp "$templates_dir/tailwind-index.css" "index.css"
                        cp "$templates_dir/eslint.config.js" "eslint.config.js"

                        return $?
                        ;;
                    prettierrc-tw|prettier-tw)
                        cp "$templates_dir/prettier-tw.config.js" "prettier.config.js"

                        return $?
                        ;;
                    twi|twi-css|tailwind-index-css)
                        cp "$templates_dir/tailwind-index.css" "index.css"

                        return $?
                        ;;
                    twc|tw-config|tailwind-config)
                        cp "$templates_dir/tailwind+twTypography+daisyui.js" "tailwind.config.js"

                        return $?
                        ;;
                    elm)
                        local templates=(
                            'elm.json'
                            'eslint.config.js'
                            'index.html'
                            'main.ts'
                            'package.json'
                            'prettier.config.js'
                            'vite.config.ts'
                        )

                        for template in "${templates[@]}"; do
                            cp "$templates_dir/elm/$template" "$template"
                        done

                        mkdir src
                        cp "$templates_dir/elm/src/Main.elm" "src/Main.elm"

                        return $?
                        ;;
                    all|proj|project|full-project)
                        local templates=(
                            '.gitattributes'
                            '.gitignore'
                            '.editorconfig'
                            'CHANGELOG.md'
                            'LICENSE.txt'
                            'tsconfig.json'
                            'package.json'
                        )

                        for template in "${templates[@]}"; do
                            cp "$templates_dir/$template" "$template"
                        done

                        mkdir src

                        return $?

                        ;;
                    *|help|--help|-h)
                        mm_trim "
                            Couldn't find a template for that. Available templates:

                            (You can use the full name or the alias to create a file from them.)

                            Template (alias)                      | File name
                            ------------------------------------------------------------------------
                            - gitattributes (gita)                | .gitattributes
                            - gitignore (giti)                    | .gitignore
                            - editorconfig (ec)                   | .editorconfig
                            - eslintrc (eslint)                   | .eslintrc.json
                            - prettierrc (prettier)               | .prettierrc.json
                            - changelog (cl)                      | CHANGELOG.md
                            - license (lic)                       | LICENSE.txt
                            - license-apache (lic-apache, apache) | LICENSE-apache.txt
                            - tsconfig (tsc)                      | tsconfig.json
                            - package (pkg)                       | basic package.json w. versions
                            - dev                                 | dev (script to help development)
                            - manifest                            | manifest.json (Chrome Ext. v3)
                            - pnpm-workspace (ws)                 | pnpm-workspace.yaml
                            - monorepo (mr)                       | [TODO] create files for a
                                                                  |     monorepo project
                            - package-c (pkg-c)                   | package.json with 'catalog:'
                            - package-tw (pkg-tw)                 | package.json with tailwind
                            - tailwind-index-css (twi)            | tailwind base index.css file
                            - tailwind-config (twc)               | tailwind config file
                            - elm                                 | create an Elm project with Vite
                            - all                                 | copy the following:
                                                                  |   - .gitattributes
                                                                  |   - .gitignore,
                                                                  |   - .editorconfig
                                                                  |   - CHANGELOG.md
                                                                  |   - LICENSE.txt
                                                                  |   - tsconfig.json
                                                                  |   - package.json
                        " 24 && false

                        return $?
                        ;;
                esac

                cp "$templates_dir/$template" "$template"
                return $?
                ;; #}}}
            eslint-prettier) #{{{
                cp "$this_file_directory/templates/package.json" "$PWD"

                npm install -D \
                    @trivago/prettier-plugin-sort-imports \
                    eslint \
                    eslint-config-google \
                    eslint-config-prettier \
                    prettier \
                    prettier-plugin-tailwindcss \
                    vite

                return $?
                ;; #}}}
            install-essentials) #{{{
                if [ ! -d /home/linuxbrew/.linuxbrew ]; then
                    echo 'Installing Homebrew...'
                    /bin/bash -c \
                        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                fi

                # Recommended by brew itself, after installation.
                brew install gcc

                # Tools.
                brew install neovim ripgrep tmux

                # Suggestions by copilot.
                # brew install \
                #     bat \
                #     deno \
                #     fd \
                #     fzf \
                #     git \
                #     htop \
                #     jq \
                #     neovim \
                #     ripgrep \
                #     tmux \
                #     tree \
                #     wget \
                #     zsh


                ;; #}}}
            curl) #{{{
                local url="$2"
                if [ -z "$url" ]; then
                    echo "ERROR: second argument ($url) should be an URL."
                    return 1
                fi

                curl -LO $url

                return $?

                ;; #}}}
            sri-hash) #{{{
                set -e

                local file_or_url="$2"
                local cmd="${3:-curl}"
                local algorithm="${4:-sha384}"

                if [ "$cmd" = "cat" ]; then
                    if [ ! -f "$file_or_url" ]; then
                        echo "ERROR: second argument ($file_or_url) should be a file."
                        return 1
                    fi

                elif [ "$cmd" = "curl" ]; then
                    if [ -z "$file_or_url" ]; then
                        echo "ERROR: second argument ($file_or_url) should be an URL."
                        return 1
                    fi
                else
                    echo "ERROR: invalid command ($cmd). Must be 'curl' or 'cat'."
                    return 1
                fi

                local the_hash="$($cmd $file_or_url | openssl dgst -$algorithm -binary | openssl base64 -A)"
                echo "integrity=\"$algorithm-$the_hash\""

                return $?

                ;; #}}}
            to-json-string)
                shift

                local file_to_run="$(mktemp)" && cat <<'EOF' > $file_to_run
const strings = process.argv.slice(2)[0].split('\n')

console.log(strings
    .map(string => JSON.stringify(string))
    .join(',\n'))
EOF

                local ret=$?

                [ $ret ] && node $file_to_run "$@" || exit $ret

                ;;
            next-here|next-command-here) #{{{
                echo 'duplicate this one and replace this'
                ;; #}}}
            *) #{{{
                # Put the next command above this line.

                fatal "Unknown parameter passed: $1"

                ;; #}}}
        esac
        shift
    done
}

main "$@"

# ==============================================================================
# Reference code.
# ==============================================================================



# Copilot generated
# -----------------


# # Posix compliant case statement.
# case "$1" in
#     "install")
#         echo "Installing dependencies..."
#         ;;
#     "start")
#         echo "Starting the project..."
#         ;;
#     "build")
#         echo "Building the project..."
#         ;;
#     "test")
#         echo "Running tests..."
#         ;;
#     *)
#         echo "Usage: $0 {install|start|build|test}"
#         ;;
# esac


# # Parse command line arguments in a posix compliant way.
# # Source: https://stackoverflow.com/a/14203146/1219006
# while [ "$#" -gt 0 ]; do
#     case "$1" in
#         -h|--help) echo "Usage: $0 {install|start|build|test}"; exit 1;;
#         -i|--install) echo install;;
#         -s|--start) echo start;;
#         *) echo "Unknown parameter passed: $1"; exit 1;;
#     esac
#     shift
# done

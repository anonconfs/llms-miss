#!/bin/bash
#
# Created by ChatGPT(GPT-3.5)
#
# Usage: bash rename-to-kebab-case.sh /path/to/your/folder
#

# 함수를 정의하여 camelCase를 kebab-case로 변환
function camelToKebab {
    echo "$1" | sed 's/\([^A-Z]\)\([A-Z]\)/\1-\2/g' | tr '[:upper:]' '[:lower:]'
}

# 주어진 경로 내의 모든 파일 및 폴더를 찾아서 처리
function convertFilenames {
    local path=$1
    for file in "$path"/*; do
        # 파일명 또는 폴더명이 camelCase인 경우에만 변경
        if [[ -e "$file" ]]; then
            base=$(basename "$file")
            if [[ $base =~ [a-z]+[A-Z] ]]; then
                kebab_case=$(camelToKebab "$base")
                new_path=$(dirname "$file")/$(echo "$kebab_case")
                mv "$file" "$new_path"
                echo "변경: $file -> $new_path"
            fi
        fi

        # 만약 폴더라면 재귀적으로 호출하여 하위 폴더 및 파일에 대해서도 처리
        if [[ -d "$file" ]]; then
            convertFilenames "$file"
        fi
    done
}

# 주어진 경로로 시작
convertFilenames "$1"

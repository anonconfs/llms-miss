#!/bin/bash
#
# A script to generate a searchable JSON file and thumbnails
# Written by ChatGPT and Daniel McFeeters
# Licensed under CC0

source "$(dirname "$0")/parsename_functions.sh"

# Function to calculate the md5sum of a file
calculate_md5sum() {
    md5sum "$1" | awk '{ print $1 }'
}

# Function to create a thumbnail image
make_thumb() {
    local image="$1"
    local md5="$2"
    local tdir="$thumbs_directory/${md5:0:1}"
    if [[ ! -e "$tdir/$md5.webp" ]]; then
	mkdir -p "$tdir"
        convert "$image" -resize "256x256" -quality 70 "$tdir/$md5.webp" &
    fi
    if [[ ! -e "$tdir/$md5.768.webp" ]]; then
	mkdir -p "$tdir"
        convert "$image" -resize "768x768" -quality 70 "$tdir/$md5.768.webp" &
    fi
}

make_video_thumb() {
    local video="$1"
    local md5="$2"
    local tdir="$thumbs_directory/${md5:0:1}"
    mkdir -p "$tdir"
    if [[ ! -e "$tdir/$md5.webp" ]]; then
        ffmpeg -y -i "$video" -ss 00:00:01.000 -vframes 1 -vf "scale=256:-1" "$tdir/$md5.webp"
    fi
    if [[ ! -e "$tdir/$md5.768.webp" ]]; then
        ffmpeg -y -i "$video" -ss 00:00:01.000 -vframes 1 -vf "scale=768:-1" "$tdir/$md5.768.webp"
    fi
}

get_desc() {
    local image="$1"
    local md5="$2"
    local tdir="$thumbs_directory/${md5:0:1}"

    # Check for a cached version and return if found
    if [[ -e "$tdir/$md5.txt" ]]; then
	local width=`head -1 "$tdir/$md5.txt"`
	local height=`tail +2 "$tdir/$md5.txt" | head -1`
	local desc=`tail +3 "$tdir/$md5.txt"`
    else
        local width=`identify -format '%w' "$image"`
        local height=`identify -format '%h' "$image"`
	local desc=$(exiftool -s -s -s -ImageDescription "$image"); [[ -z "$desc" ]] && desc=$(exiftool -s -s -s -XMP-dc:Description "$image")
        echo "$width" > "$tdir/$md5.txt"
        echo "$height" >> "$tdir/$md5.txt"
        echo "$desc" >> "$tdir/$md5.txt"
    fi
    case $3 in
	    width)
		    echo -n $width
		    ;;
	    height)
		    echo -n $height
		    ;;
	    desc)
		    echo -n $desc
		    ;;
    esac

}

get_video_desc() {
    local file="$1"
    local md5="$2"
    local tdir="$thumbs_directory/${md5:0:1}"
    if [[ -e "$tdir/$md5.txt" ]]; then
        width=$(head -1 "$tdir/$md5.txt")
        height=$(tail +2 "$tdir/$md5.txt" | head -1)
        desc=$(tail +3 "$tdir/$md5.txt")
    else
        width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$file")
        height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$file")
        desc=$(ffprobe -v quiet -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$file")
        echo "$width" > "$tdir/$md5.txt"
        echo "$height" >> "$tdir/$md5.txt"
        echo "$desc" >> "$tdir/$md5.txt"
    fi
    case $3 in
        width) echo -n "$width" ;;
        height) echo -n "$height" ;;
        desc) echo -n "$desc" ;;
    esac
}

get_audio_desc() {
    local file="$1"
    local md5="$2"
    local tdir="$thumbs_directory/${md5:0:1}"
    local title
    local artist
    local comment
    local desc

    if [[ -e "$tdir/$md5.txt" ]]; then
        desc=$(cat "$tdir/$md5.txt")
    else
        mkdir -p "$tdir"
        title=$(ffprobe -v quiet -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$file")
        artist=$(ffprobe -v quiet -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$file")
        comment=$(ffprobe -v quiet -show_entries format_tags=comment -of default=noprint_wrappers=1:nokey=1 "$file")

        if [[ -n "$title" && -n "$artist" ]]; then
            desc="$title - $artist"
        elif [[ -n "$title" ]]; then
            desc="$title"
        elif [[ -n "$comment" ]]; then
            desc="$comment"
        else
            desc=""
        fi

        printf '%s\n' "$desc" > "$tdir/$md5.txt"
    fi

    echo -n "$desc"
}

urlencode() {
	jq -rn --arg x "$1" '$x|@uri'
}


# Function to process a directory
process_directory() {
    local dir="$1"

        # Get the relative path of the image
    relative_d="${1#$base_directory}"

    if [[ "$relative_d" =~ \/extra$ ]]; then
        return 1
    fi
    if [[ "$relative_d" =~ \/original$ ]]; then
        return 1
    fi
    if [[ "$relative_d" =~ \/todo$ ]]; then
        return 1
    fi
    echo -e "\e[1A\e[KDirectory $relative_d"
    echo ""

    
    # Loop through files in the directory
    find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mp3" \) -print0 |
	        while IFS= read -r -d '' file; do

	# Skip .4k.webm files if a corresponding .mp4 exists
	if [[ "$file" =~ \.4k\.webm$ ]]; then
	    base="${file%.4k.webm}"
	    mp4_version="${base}.mp4"
	    if [[ -f "$mp4_version" ]]; then
	        continue
	    fi
	fi
        filename=$(basename "$file")
	echo -e "\e[1A\e[KProcessing $filename"
        filepath=$(realpath "$file")
	relative_path="${filepath#$base_directory/}"
	bnum=""
	if [[ "$relative_path" =~ ^([0-9]+) ]]; then
		bnum="${BASH_REMATCH[1]}"
	fi
	dir="$(dirname "$relative_path")"
        md5=$(calculate_md5sum "$file")
	xx=""
	if [[ "$file" =~ "XX" ]]; then
	        xx="XX"
	fi
        license=$(get_copyright "$file" license)
        attribution=$(get_copyright "$file" attribution)
        lower_filename="${filename,,}"
        if [[ "$lower_filename" =~ \.mp4$ || "$lower_filename" =~ \.webm$ ]]; then
            make_video_thumb "$file" "$md5"
            desc=$(get_video_desc "$file" "$md5" desc)
            width=$(get_video_desc "$file" "$md5" width)
            height=$(get_video_desc "$file" "$md5" height)
	    mfilename=$filename
	    medurl="$med_baseurl/download?path=`urlencode "/$dir"`&files=`urlencode "$mfilename"`" 
	    meddirlink="$med_baseurl?path=`urlencode "/$dir"`" 
	    # Calculate large url if .4k.webm version exists
	    #
	        # Calculate large URL if .4k.webm version exists
               basemp4="${filename%.mp4}"
               highres_file="$base_directory/$dir/${basemp4}.4k.webm"
               if [[ -f "$highres_file" ]]; then
                   highfilename="${basemp4}.4k.webm"
                   largeurl="$high_baseurl/download?path=$(urlencode "/$dir")&files=$(urlencode "$highfilename")"
                   bigdirlink="$meddirlink"
               else
                   largeurl=""
                   bigdirlink=""
               fi
            ftype="video"
        elif [[ "$lower_filename" =~ \.mp3$ ]]; then
            desc=$(get_audio_desc "$file" "$md5")
            width="0"
            height="0"
            mfilename=$filename
            if [[ "$med_baseurl" == "" ]]; then
                medurl=""
                meddirlink=""
            else
                medurl="$med_baseurl/download?path=$(urlencode "/$dir")&files=$(urlencode "$mfilename")"
                meddirlink="$med_baseurl?path=$(urlencode "/$dir")"
            fi
            largeurl=""
            bigdirlink=""
            ftype="audio"
        else
            make_thumb "$file" "$md5"
            desc=$(get_desc "$file" "$md5" desc)
            width=$(get_desc "$file" "$md5" width)
            height=$(get_desc "$file" "$md5" height)
	    mfilename=${filename/\.webp/.jpg}
	    mfilename=${mfilename/\.png/.jpg}
            ftype="image"
	    if [[ "$med_baseurl" == "" ]]; then
	        medurl=""
	        meddirlink=""
	    else
	        medurl="$med_baseurl/download?path=`urlencode "/$dir"`&files=`urlencode "$mfilename"`" 
	        meddirlink="$med_baseurl?path=`urlencode "/$dir"`" 
	    fi
	    largeurl="$high_baseurl/download?path=`urlencode "/$dir"`&files=`urlencode "$filename"`" 
	    bigdirlink="$high_baseurl?path=`urlencode "/$dir"`" 
	    if [[ "$file" =~ "XX" ]]; then
	        medurl=""
	        meddirlink=""
	    fi
        fi

	sourceurl=$(get_sourcelink "$file" link $default_type)

	# If sourceurl is empty, extract first URL from desc
	if [[ -z "$sourceurl" && -n "$desc" ]]; then
	    sourceurl=$(echo "$desc" | grep -oE 'https?://[^[:space:]]+' | head -n 1)
	fi

	arttype=$(get_sourcelink "$file" type $default_type)
	ai="no"
	if [[ "$arttype" =~ ^AI\ Generated ]]; then
		ai="yes"
	fi
	date=$(stat -c %y "$file")

        # Output JSON for the current file
        jq -n --arg filename "$filename" \
	      --arg dir "$dir" \
	      --arg bnum "$bnum" \
	      --arg md5 "$md5" \
	      --arg desc "$desc" \
	      --arg width "$width" \
	      --arg height "$height" \
	      --arg license "$license" \
	      --arg attribution "$attribution" \
	      --arg medurl "$medurl" \
	      --arg largeurl "$largeurl" \
	      --arg meddirlink "$meddirlink" \
	      --arg bigdirlink "$bigdirlink" \
	      --arg sourceurl "$sourceurl" \
	      --arg arttype "$arttype" \
	      --arg xx "$xx" \
	      --arg ai "$ai" \
	      --arg date "$date" \
	      --arg ftype "$ftype" \
            '{filename: $filename, dir: $dir, bnum: $bnum, md5: $md5, desc: $desc, width: $width, height: $height, license: $license, attribution: $attribution, medurl: $medurl, largeurl: $largeurl, meddirlink: $meddirlink, bigdirlink: $bigdirlink, sourceurl: $sourceurl, arttype: $arttype, xx: $xx, ai: $ai, date: $date, ftype: $ftype}' \
	          >> "$thumbs_directory/snapshots.json"
	echo -n ',' >> "$thumbs_directory/snapshots.json"

	# Wait for spawned processes
	num_children=`ps --no-headers | grep convert | wc -w`
	while [ "$num_children" -gt "8" ]; do
	    echo -e "\e[1A\e[KWaiting for ($num_children processes)"
	    echo ""
	    sleep 1
	    num_children=`ps --no-headers | grep convert | wc -w`
	done
    done
}

# Main function
main() {
    local target_directory="$1"

    # Check if the target directory exists
    if [ ! -d "$target_directory" ]; then
        echo "Error: The specified directory does not exist."
        exit 1
    fi

    # Start JSON array
    echo "[" > "$thumbs_directory/snapshots.json"

    # Process the target directory and its subdirectories
    find "$target_directory" -type d -print0 | while IFS= read -r -d '' directory; do
        process_directory "$directory"
    done

    # End JSON array
    echo "{}]" >> "$thumbs_directory/snapshots.json"
}

# Check if the target directory is provided
if [ -z "$3" ]; then
    echo "Usage: $0 <target_directory> <thumbs_directory> <default_type>"
    exit 1
fi

# Run the main function with the provided target directory
base_directory=$(realpath "$1")
thumbs_directory=$(realpath "$2")
default_type="$3"
med_baseurl=`cat "$base_directory/med_baseurl.md"`
high_baseurl=`cat "$base_directory/high_baseurl.md"`
echo Starting
main "$base_directory"

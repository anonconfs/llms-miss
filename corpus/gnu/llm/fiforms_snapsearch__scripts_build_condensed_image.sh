#!/bin/bash

# Program written by ChatGPT and Daniel McFeeters
# Released to the public domain (CC0)
#
# November 2023

# Set the maximum size for the images
max_width=3840
max_height=2160
min_ratio=1749
max_ratio=1787
share_baseuri="https://cloud.fiforms.org/dan_cloud/index.php/s/TrjZLnLdf7QHcBY"

# Input and output directories
input_dir="./"
output_dir="../Virtual Bible Snapshots - Condensed/"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Find all image files in the input directory and its subdirectories (excluding hidden directories)
find "$input_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.md" -o -iname "*.kml" -o -iname "*.mp4" \) | while read -r image; do

    # Get the relative path of the image
    relative_path="${image#$input_dir}"

    if [[ "$relative_path" =~ .*\/\..*/ ]]; then
        continue
    fi
    if [[ "$relative_path" =~ \/extra\/ ]]; then
        continue
    fi
    if [[ "$relative_path" =~ \/original\/ ]]; then
        continue
    fi
    if [[ "$relative_path" =~ \/todo\/ ]]; then
        continue
    fi
    if [[ "$relative_path" =~ \/scripts\/ ]]; then
        continue
    fi
    if [[ "$relative_path" =~ \/symbols\/ ]]; then
        continue
    fi

    # Create the corresponding output directory
    dirpath=$(dirname "$relative_path")
    mkdir -p "$output_dir/$dirpath"
    origlink="$output_dir/$dirpath/0000 Link to Original Files.md"
    if ! [[ -e "$origlink" ]]; then
        # Create a file for documentation to link to original size images
        echo -n $share_baseuri?path=%2F > "$origlink"
        jq -rn --arg x "$dirpath" '$x|@uri' >> "$origlink"
    fi
    if [[ "$relative_path" =~ \.md$ ]] || [[ "$relative_path" =~ \.kml$ ]] || [[ "$relative_path" =~ \.mp4$ ]]; then
	if [ "$image" -nt "$output_dir/$relative_path" ]; then    
	    cp "$image" "$output_dir/$relative_path"
	fi
        continue
    fi
    if [[ "$relative_path" =~ XX ]]; then
        continue
    fi
    output_file=$(echo "$relative_path" | sed 's/\.png$/.jpg/')
    output_file=$(echo "$output_file" | sed 's/\.webp$/.jpg/')

    # Check if the output file exists and if the input file is more recent
    if [ ! -e "$output_dir/$output_file" ] || [ "$image" -nt "$output_dir/$output_file" ]; then
	width=`identify -format '%w' "$image"`
	height=`identify -format '%h' "$image"`
	ratio=$width*1000/$height
	if [[ ${width} -gt ${max_width} ]] || [[ ${height} -gt ${max_height} ]]; then
	    echo -n Converting and Scaling $image from ${width} x ${height} to ${max_width} x ${max_height}
            # Resize the image and save it to the output directory
	    if [[ $ratio -gt $min_ratio && $ratio -lt $max_ratio ]]; then
		operator="!"
		echo " (stretched)"
	    else
		operator=">"
		echo " (fit)"
	    fi
            convert "$image" -resize "${max_width}x${max_height}${operator}" -unsharp 0x2+0.8+0  -quality 88 "$output_dir/$output_file"
        else
	    if [[ "$relative_path" == "$output_file" ]]; then
	        echo Copying $image
		cp "$image" "$output_dir/$output_file"
	    else
	        echo Converting $image
                convert "$image" -quality 88 "$output_dir/$output_file"
	    fi
	fi
    fi
done

# Find and delete extraneous files from $output_dir
find "$output_dir" -type f | while read -r image; do
    # Get the relative path of the image
    relative_path="${image#$output_dir}"
    # echo ${#relative_path}
    if [[ ${#relative_path} -gt 220 ]]; then
	echo Long Path Name: $relative_path
    fi
    if [[ "$relative_path" =~ 0000\ Link\ to\ Original\ Files.md$ ]]; then
	    continue;
    fi

    if [ ! -e "$input_dir/$relative_path" ]; then
	    png_version=$(echo "$relative_path" | sed 's/\.jpg$/.png/')
	    if [ ! -e "$input_dir/$png_version" ]; then
	    	webp_version=$(echo "$relative_path" | sed 's/\.jpg$/.webp/')
	        if [ ! -e "$input_dir/$webp_version" ]; then
		    echo "Deleting $image"
		    rm "$image"
	        fi
	    fi
    fi
done

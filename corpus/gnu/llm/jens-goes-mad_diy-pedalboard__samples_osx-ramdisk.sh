#!/bin/bash

# shell script created by ChatGPT
#
# can you create a shell-script to create and delete ramdisks on macosx parameters size and name?

# Function to show usage
usage() {
  echo "Usage:"
  echo "  $0 create <size_in_MB> <name>"
  echo "  $0 delete <name>"
  exit 1
}

# Function to create RAM disk
create_ramdisk() {
  size_mb=$1
  name=$2

  if [[ -z "$size_mb" || -z "$name" ]]; then
    usage
  fi

  # Convert MB to 512-byte sectors (1MB = 2048 sectors)
  sectors=$((size_mb * 2048))

  # Create the RAM disk and mount it
  device=$(hdiutil attach -nomount ram://$sectors)
  if [ $? -ne 0 ]; then
    echo "Failed to create RAM disk"
    exit 1
  fi

  # Format the RAM disk with HFS+ and mount
  diskutil eraseVolume HFS+ "$name" ${device}

  echo "RAM disk '$name' created at $device and mounted in /Volumes/$name"
}

# Function to delete RAM disk
delete_ramdisk() {
  name=$1

  if [[ -z "$name" ]]; then
    usage
  fi

  volume_path="/Volumes/$name"

  if [ ! -d "$volume_path" ]; then
    echo "Volume '$name' not found at $volume_path"
    exit 1
  fi

  # Unmount and detach
  diskutil unmount "$volume_path"
  device=$(hdiutil info | grep "$volume_path" | awk '{print $1}')
  if [[ -n "$device" ]]; then
    hdiutil detach "$device"
    echo "RAM disk '$name' detached"
  else
    echo "Could not find device for '$name'"
  fi
}

# Main script logic
if [[ $# -lt 2 ]]; then
  usage
fi

command=$1

case $command in
  create)
    create_ramdisk $2 $3
    ;;
  delete)
    delete_ramdisk $2
    ;;
  *)
    usage
    ;;
esac

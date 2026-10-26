#!/bin/bash

# Script written by ChatGPT

# Check if a new hostname is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 new_hostname"
    exit 1
fi

new_hostname=$1

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Change the hostname immediately
hostnamectl set-hostname $new_hostname

# Update /etc/hostname for persistence across reboots
echo $new_hostname > /etc/hostname

# Update /etc/hosts to ensure local resolution works
sed -i "s/127.0.1.1\s.*/127.0.1.1\t$new_hostname/g" /etc/hosts

echo "Hostname changed to $new_hostname"

#!/bin/bash
# written by ChatGPT

# Update package manager's package list
sudo pacman -Sy

# Install dependencies
sudo pacman -S --needed ghostscript libjpeg libpng libtiff freetype2

# Install cups
sudo pacman -S --needed cups cups-filters foomatic-db-engine foomatic-db foomatic-db-ppds foomatic-db-nonfree foomatic-db-nonfree-ppds

#ghostscript: An interpreter for the PostScript language and for PDF. It is used by cups to convert PostScript and PDF files to a format that can be printed.
#libjpeg: A library for reading and writing JPEG image files. It is used by cups to support printing of JPEG images.
#libpng: A library for reading and writing PNG image files. It is used by cups to support printing of PNG images.
#freetype2: A library for rendering text to bitmaps. It is used by cups to support printing of text.


#Gutenprint is a printer driver that provides high quality printer support for a wide variety of printers. 
#If you want to use Gutenprint with cups, you can install it with the following command:
sudo pacman -S --needed gutenprint

#Gutenprint is not a dependency of cups, but it can be used as an alternative or additional printer driver. Once Gutenprint is installed, you will need to configure cups to use it.

#To configure cups to use Gutenprint, follow these steps:
#
#    Open the cups web interface in a web browser by going to http://localhost:631/.
#    Click on the "Administration" tab.
#    Click on the "Add Printer" button.
#    Select the printer you want to add from the list of available printers.
#    In the "Make and Model" dropdown menu, select "Gutenprint v5.3 (en)".
#    Click the "Continue" button.
#    Follow the prompts to complete the printer setup.
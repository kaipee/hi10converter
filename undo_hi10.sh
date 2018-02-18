#! /bin/bash

# Define colours for fancy-pants output
readonly NC='\033[0m'
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[1;34m'
readonly CYAN='\033[1;36m'

read -p "Please enter path of logfile: " HI10VIDINPUT

while read -r video_file; do

  ## VARIABLES
  DIR=$(dirname "$video_file")
  #VIDFILE=$(basename "$video_file" | cut -f 1 -d '.')
  VID=$(basename "$video_file")

  ## CHECK THE FILE WAS ACTUALLY CONVERTED AND ORIGINAL MOVED TO /10BIT
  printf "\nchecking $VID was previously converted and moved to $DIR/10bit\n"
  if [ -d "$DIR/10bit" ]; then

    ## CREATE UNDO SUBDIRECTORY TO HOLD CONVERTED FILE
    printf "creating subdirectory to store converted new 8bit file : ($DIR/undo)\n" # this directory and converted video can be manually deleted later once everything goes OK
    mkdir -p "$DIR/undo"
    if [ -d "$DIR/undo" ]; then # Check undo directory got created successfully
      mv "$video_file" "$DIR/undo" # mv the new 8bit file to /undo for deletion
        if [ $? -eq 0 ]; then
          printf "${GREEN}Success${NC}...moved ${video_file}\n"
        else
          printf "${RED}Ooops, something went wrong...exiting!${NC} : problem moving ${video_file}\n"
          exit 1
        fi
      mv "$DIR/10bit/$VID" "$video_file" # move the original 10bit file back in place
        if [ $? -eq 0 ]; then
          printf "${GREEN}Success${NC}...moved $DIR/10bit/$VID\n"
        else
          printf "${RED}Ooops, something went wrong...exiting!${NC} : problem moving /10bit/$VID\n"
          exit 1
        fi
    else
      printf "${RED}Ooops, something went wrong...exiting!${NC} : problem creating $DIR/undo\n" # Print error message and exit
      printf "Tried to move $video_file\n"
      exit 1
    fi
    
  else
    : # do nothing
  fi

done < $HI10VIDINPUT
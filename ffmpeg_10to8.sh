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
  VIDFILE=$(basename "$video_file" | cut -f 1 -d '.')

  ## CREATE 8BIT SUBDIRECTORY TO HOLD CONVERTED FILE
  printf "\n\ncreating subdirectory to store converted 8bit file : ($DIR/8bit) \n\n"
  mkdir -p "$DIR/8bit"
  if [ -d "$DIR/8bit" ]; then # Check 8bit directory got created successfully
    : # Do nothing
  else
    printf "$(RED)Ooops, something went wrong...exiting!${NC} : problem creating $DIR/8bit" # Print error message and exit
    exit 1
  fi

  ## CONVERT THE 10BIT VIDEO TO 8BIT USING X264, MKV, KEEPING ORIGINAL AUDIO STREAMS
  ## LOWER -CRF FOR BETTER QUALITY (18 IS GOOD BALANCE OF QUALITY/SIZE)
  ffmpeg -i "$video_file" -map 0 -c copy -c:v libx264 -crf 18 "$DIR/8bit/$VIDFILE.mkv" < /dev/null; # ffmpeg takes input from stdin, replacing stdin with null to prevent issues

  if [ $? -eq 0 ]; then # do not move any files if ffmpeg does not complete

    ## MOVE 10BIT ORIGINAL TO SUBDIRECTORY FOR BACKUP
    printf "\n\ncreating subdirectory to backup original 10bit file : ($DIR/10bit) \n\n"
    mkdir -p "$DIR/10bit"
    if [ -d "$DIR/10bit" ]; then # Check 8bit directory got created successfully
      mv "$video_file" "$DIR/10bit/" # Move original video to backup directory
    else
      printf "$(RED)Ooops, something went wrong...exiting!${NC} : problem creating $DIR/10bit" # Print error message and exit
      exit 1
    fi

    ## MOVE CONVERTED 8BIT FILE TO ORIGINAL DIRECTORY SO IT GETS PICKED UP BY MEDIA PLAYERS, ETC.
    printf "\n\nmoving converted 8bit video to original directory and cleaning up"
    mv "$DIR/8bit/$VIDFILE.mkv" "$DIR/"
    if [ $? -eq 0 ]; then # Check 8bit directory got created successfully
      rm -rf "$DIR/8bit"
    else
      printf "$(RED)Ooops, something went wrong...exiting!${NC} : problem moving $DIR/8bit/$VIDFILE.mkv" # Print error message and exit
      exit 1
    fi

  else
    exit 1
  fi

done < $HI10VIDINPUT

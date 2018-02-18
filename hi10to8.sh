#!/bin/bash

# Author:	Keith Patton 2016
# Brief:	A BASH script for finding all video files
# 		within the current directory, and subdirectories, and converting from
# 		10bit Bit Depth to 8bit Bit Depth using ffmpeg

# DEFINE VARIABLES/CONSTANTS
# Create multiple logs for each stage so they can be used for backup/recovery; error-checking; history; etc.
readonly TMPDIR="/tmp/hi10conversion" # make TMP working directory
readonly HI10SHORT="/tmp/hi10conversion/all_files_relative.log"  # log of ALL files in current dir/subdir (relative paths)
readonly HI10LONG="/tmp/hi10conversion/all_files_full.log"  # log of ALL files in current dir/subdir (full URI)
readonly HI10VID="/tmp/hi10conversion/video_only_mime.log"  # filtered log containing only files with VIDEO mimetype (full URI with mimetype)
readonly HI10VIDSTRIP="/tmp/hi10conversion/video_only.log"  # cleaned list of only video files (full URI without mimetype appended)
readonly HI10VIDDEPTH="/tmp/hi10conversion/video_bitdepth.log"  # list of all video files with bit depth appended (full URI with bit depth)
readonly HI10VID10="/tmp/hi10conversion/video_10bit.log"  # list of all video files filtered to ONLY 10 Bit Depth (full URI with 10 bit depth)
readonly HI10VID10STRIP="/tmp/hi10conversion/videos_for_conversion.log"  # final list of all video files in current and all sub-dir, filtered to contain only 10 bit depth files (full URI with 10 bit)

# Define colours for fancy-pants output
readonly NC='\033[0m'
readonly RED='\033[1;31m'
readonly GREEN='\033[1;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[1;34m'
readonly CYAN='\033[1;36m'

# Clear the screen before running the script
clear

# PRE-WARN #
printf "${RED}THIS SCRIPT USES ARRAYS, PLEASE MAKE SURE YOU EXECUTE THE SCRIPT USING BASH - NOT SH, CSH, ETC...${NC}\n\n"


#########################################
# CONFIRM THE CORRECT DIRECTORY TO SCAN #
#########################################

# LAZY : could probably take an actual input to confirm the directory to work from but meh, this works

CWD=$(pwd)
while true; do
  read -r -p "This script will scan $CWD and all subdirectories, is this correct? (y/n) " dir_confirm
  case $dir_confirm in
    [Yy]* )
      break;;
    [Nn]* )
      printf "${RED}Please cd to correct directory that contains videos and call script again.${NC}\n\n"
      exit 1;;
    * ) printf "Please answer y or n.";;
  esac
done


#########################################################
# PRESENT OPTION TO RUN AUTOMATICALLY OR WAIT FOR INPUT #
#########################################################

while true; do
  read -r -p $'\e[33mRun script automatically? (y/n) \e[0m' autorun
  case $autorun in
    [Yy]* )
      readonly AUTORUN="y"
      break;;
    [Nn]* )
      readonly AUTORUN="n"
      break;;
    * ) printf "Please answer y or n.";;
  esac
done


#########################################
# CREATE TMP WORKING DIRECTORY FOR LOGS #
#########################################

printf "\n${CYAN}CREATING TMP WORKING DIRECTORY TO STORE LOGS${NC}\n"
sleep 3

mkdir -p "$TMPDIR" # Create tmp working directory
if [ -d "$TMPDIR" ]; then # Check tmp working directory actually exists
  printf "${GREEN}SUCCESS${NC} : created $TMPDIR\n" # Print success if tmp working directory exists
else
  printf "$(RED)Ooops, something went wrong...exiting!${NC} : problem creating $TMPDIR" # Print error message and exit
  exit 1
fi


###########################################
# CLEAN UP ANY PREVIOUSLY SAVED LOG FILES #
###########################################

if [ $AUTORUN != "y" ]; then # Check for autorun
  # PROMPT FOR CONFIRMATION TO PROCEED
  while true; do
    printf "\nNext step is to clean up any previous logs\n"
    read -r -p $'\e[33mDo you wish to continue? (y/n) \e[0m' yn
    case $yn in
      [Yy]* )
        break;;
      [Nn]* ) exit;;
      * ) printf "Please answer y or n.";;
    esac
  done
fi

printf "\n${CYAN}CLEANING UP PREVIOUS LOG FILES${NC}\n"
sleep 3

# Create short array of log paths
readonly logarray=( "$HI10SHORT" "$HI10LONG" "$HI10VID" "$HI10VIDSTRIP" "$HI10VIDDEPTH" "$HI10VID10" "$HI10VID10STRIP" )

# Check for existing logs and delete them, or continue
for log in "${logarray[@]}"; do
  if test -f "$log"
  then
    printf "deleting $log ..."
    rm $log
    printf "${GREEN}done${NC}\n"
  else
    printf "no previous file list found at $log\n"
  fi
done


######################################################
# FIND ALL FILES IN THE CURRENT AND SUB- DIRECTORIES #
######################################################

if [ $AUTORUN != "y" ]; then # Check for autorun
  # PROMPT FOR CONFIRMATION TO PROCEED
  while true; do
    printf "\n"
    printf "\nNext step is to find all files in current and sub-directories\n"
    read -r -p $'\e[33mDo you wish to continue? (y/n) \e[0m' yn
    case $yn in
      [Yy]* )
        break;;
      [Nn]* ) exit;;
      * ) printf "Please answer y or n.";;
    esac
  done
fi

printf "\n${CYAN}SEARCHING FOR ALL FILES IN CURRENT WORKING DIRECTORY${NC}\n"
sleep 3

FILES="$(find ./ -type f)"  # Find all files in the current (and sub-) directories
printf "$FILES" > $HI10SHORT  # Save to log file for future use
cat $HI10SHORT  # Output all files to screen for verification

sleep 1
printf "\n\n${GREEN}Done!${NC}...(log saved to $HI10SHORT)\n"
sleep 1
WC="$(wc -l < $HI10SHORT)"
printf "${CYAN}$WC${BLUE} files total${NC}\n"


##############################################################################
# Filter through the list of files and retrieve the absolute path to be used #
##############################################################################

if [ $AUTORUN != "y" ]; then # Check for autorun
  # PROMPT FOR CONFIRMATION TO PROCEED
  while true; do
    printf "\n"
    printf "\nNext step is to convert files to absolute paths for future use\n"
    read -r -p $'\e[33mDo you wish to continue? (y/n) \e[0m' yn
    case $yn in
      [Yy]* )
        break;;
      [Nn]* ) exit;;
      * ) printf "Please answer y or n.";;
    esac
  done
fi

printf "\n${CYAN}CONVERTING TO ABSOLUTE PATHS${NC}\n"
sleep 3

while read -r path; do
  readlink -f "$path" >> $HI10LONG
done < $HI10SHORT
cat "$HI10LONG"

sleep 2
printf "\n\n${GREEN}Done!${NC}...(log saved to $HI10LONG)\n"
sleep 1
WC="$(wc -l < $HI10LONG)"
printf "${CYAN}$WC${BLUE} files total${NC}\n"


#####################################################################################
# Parse through the list of absolute files paths and filter to show only video files #
#####################################################################################

if [ $AUTORUN != "y" ]; then # Check for autorun
  # PROMPT FOR CONFIRMATION TO PROCEED
  while true; do
    printf "\n"
    printf "\nNext step is to check mime-type for each file then show only videos\n"
    read -r -p $'\e[33mDo you wish to continue? (y/n) \e[0m' yn
    case $yn in
      [Yy]* )
        break;;
      [Nn]* ) exit;;
      * ) printf "Please answer y or n.";;
    esac
  done
fi

printf "\n${CYAN}FILTERING TO SHOW ONLY VIDEO FILES${NC}\n"
sleep 3

while read -r fullpath; do
  file --mime-type "$fullpath" | grep ": video/" >> $HI10VID
done < $HI10LONG
cat "$HI10VID"

sleep 2
printf "\n\n${GREEN}Done!${NC}...(log saved to $HI10VID)\n"
sleep 1
WC="$(wc -l < $HI10VID)"
printf "${CYAN}$WC${BLUE} files total${NC}\n"


##########################################
# STRIP MIMETYPE FROM LOG FOR FUTURE USE #
##########################################

if [ $AUTORUN != "y" ]; then # Check for autorun
  # PROMPT FOR CONFIRMATION TO PROCEED
  while true; do
    printf "\n"
    printf "\nNext step is to remove the mime-type text\n"
    read -r -p $'\e[33mDo you wish to continue? (y/n) \e[0m' yn
    case $yn in
      [Yy]* )
        break;;
      [Nn]* ) exit;;
      * ) printf "Please answer y or n.";;
    esac
  done
fi

printf "\n${CYAN}STRIPPING MIMETYPE FROM EACH LINE IN LOG${NC}\n"
sleep 3

while read -r vidonly; do
  echo "$vidonly" | sed 's/: video[^ ]*$//' >> $HI10VIDSTRIP
done < $HI10VID
cat "$HI10VIDSTRIP"

sleep 2
printf "\n\n${GREEN}Done!${NC}...(log saved to $HI10VIDSTRIP)\n"
sleep 1
WC="$(wc -l < $HI10VIDSTRIP)"
printf "${CYAN}$WC${BLUE} files total${NC}\n"


#################################
# FIND BIT DEPTH OF VIDEO FILES #
#################################

if [ $AUTORUN != "y" ]; then # Check for autorun
  # PROMPT FOR CONFIRMATION TO PROCEED
  while true; do
    printf "\n"
    printf "\nNext step is to find the bit depth of each video file\n"
    read -r -p $'\e[33mDo you wish to continue? (y/n) \e[0m' yn
    case $yn in
      [Yy]* )
        break;;
      [Nn]* ) exit;;
      * ) printf "Please answer y or n.";;
    esac
  done
fi

printf "\n${CYAN}FINDING BIT DEPTH OF VIDEO FILES${NC}\n"
sleep 3

while read -r abs_vid; do
  DEPTH="$(mediainfo --Output="Video;%BitDepth%" "$abs_vid")"
  echo "$abs_vid: depth=$DEPTH" >> $HI10VIDDEPTH
done < $HI10VIDSTRIP
cat "$HI10VIDDEPTH"

sleep 2
printf "\n\n${GREEN}Done!${NC}...(log saved to $HI10VIDDEPTH)\n"
sleep 1
WC="$(wc -l < $HI10VIDDEPTH)"
printf "${CYAN}$WC${BLUE} files total${NC}\n"


##################################################
# FILTER BIT DEPTH LOG TO SHOW ONLY 10BIT VIDEOS #
##################################################

if [ $AUTORUN != "y" ]; then # Check for autorun
  # PROMPT FOR CONFIRMATION TO PROCEED
  while true; do
    printf "\n"
    printf "\nNext step is to filter the list to show only 10 bit videos\n"
    read -r -p $'\e[33mDo you wish to continue? (y/n) \e[0m' yn
    case $yn in
      [Yy]* )
        break;;
      [Nn]* ) exit;;
      * ) printf "Please answer y or n.";;
    esac
  done
fi

printf "\n${CYAN}FILTERING DEPTH LOG TO SHOW ONLY 10BIT VIDEO FILES${NC}\n"
sleep 3

while read -r filter_depth; do
  echo "$filter_depth" | grep ": depth=10" >> $HI10VID10
done < $HI10VIDDEPTH
cat "$HI10VID10"

sleep 2
printf "\n\n${GREEN}Done!${NC}...(log saved to $HI10VID10)\n"
sleep 1
WC="$(wc -l < $HI10VID10)"
printf "${CYAN}$WC${BLUE} files total${NC}\n"


############################################
# STRIP BIT DEPTH FROM LOG TO BE PROCESSED #
############################################

if [ $AUTORUN != "y" ]; then # Check for autorun
  # PROMPT FOR CONFIRMATION TO PROCEED
  while true; do
    printf "\n"
    printf "\nNext step is to removed the Bit Depth text from the log\n"
    read -r -p $'\e[33mDo you wish to continue? (y/n) \e[0m' yn
    case $yn in
      [Yy]* )
        break;;
      [Nn]* ) exit;;
      * ) printf "Please answer y or n.";;
    esac
  done
fi

printf "\n${CYAN}STRIPPING BIT DEPTH FROM EACH LINE IN LOG${NC}\n"
sleep 3

while read -r depth10; do
  echo "$depth10" | sed 's/: depth=[^ ]*$//' >> $HI10VID10STRIP
done < $HI10VID10
cat "$HI10VID10STRIP"

sleep 2
printf "\n\n${GREEN}Done!${NC}....(saved to $HI10VID10STRIP)\n"
sleep 1
WC="$(wc -l < $HI10VID10STRIP)"
printf "${CYAN}$WC${BLUE} files total${NC}\n"


############################################################################################
# PASS EACH 10BIT VIDEO FILE INTO FFMPEG FOR CONVERSION AND SAVE UNDER ./8BIT SUBDIRECTORY #
############################################################################################

if [ $AUTORUN != "y" ]; then # Check for autorun
  # PROMPT FOR CONFIRMATION TO PROCEED
  while true; do
    printf "\n"
    read -r -p $'\e[33mAre you ready to convert all files using ffmpeg? (y/n)\e[0m' yn
    case $yn in
      [Yy]* )
        break;;
      [Nn]* ) exit;;
      * ) printf "Please answer y or n.";;
    esac
  done
fi

printf "\n${CYAN}PASSING FILES TO FFMPEG FOR CONVERSION TO 8BIT${NC}\n"
sleep 3

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

done < $HI10VID10STRIP

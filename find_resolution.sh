#!/bin/bash

# Author: Keith Patton 2016
# Brief:  A BASH script for finding all video files
#         within the current directory, and subdirectories, and converting from
#         10bit Bit Depth to 8bit Bit Depth using ffmpeg

# DEFINE VARIABLES/CONSTANTS
# Create multiple logs for each stage so they can be used for backup/recovery; error-checking; history; etc.
readonly TMPDIR="/tmp/hi10conversion" # make TMP working directory
readonly HI10SHORT="/tmp/hi10conversion/all_files_relative.log"  # log of ALL files in current dir/subdir (relative paths)
readonly HI10LONG="/tmp/hi10conversion/all_files_full.log"  # log of ALL files in current dir/subdir (full URI)
readonly HI10VID="/tmp/hi10conversion/video_only_mime.log"  # filtered log containing only files with VIDEO mimetype (full URI with mimetype)
readonly HI10VIDSTRIP="/tmp/hi10conversion/video_only.log"  # cleaned list of only video files (full URI without mimetype appended)
readonly HI10VIDRES="/tmp/hi10conversion/video_resolution.log"  # list of all video files with resolution appended (full URI with resolution)

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
readonly logarray=( "$HI10SHORT" "$HI10LONG" "$HI10VID" "$HI10VIDSTRIP" "$HI10VIDRES" )

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


##################################
# FIND RESOLUTION OF VIDEO FILES #
##################################

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

printf "\n${CYAN}FINDING RESOLUTION OF VIDEO FILES${NC}\n"
sleep 3

while read -r abs_vid; do
  RESOLUTION="$(mediainfo --Output="Video;%Width% x %Height%" "$abs_vid")"
  echo "$abs_vid: $RESOLUTION" >> $HI10VIDRES
done < $HI10VIDSTRIP
cat "$HI10VIDRES"

sleep 2
printf "\n\n${GREEN}Done!${NC}...(log saved to $HI10VIDRES)\n"
sleep 1
WC="$(wc -l < $HI10VIDRES)"
printf "${CYAN}$WC${BLUE} files total${NC}\n"

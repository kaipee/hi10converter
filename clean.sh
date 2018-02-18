#!/bin/bash

while read video_file; do

  ## VARIABLES
  DIR=$(dirname "$video_file")
  VIDFILE=$(basename "$video_file" | cut -f 1 -d '.')

  ## CREATE 8BIT SUBDIRECTORY TO HOLD CONVERTED FILE
  printf "\n\ncreating subdirectory to store converted 8bit file : ($DIR/8bit) \n\n"
  mkdir -p "$DIR/8bit"

  ## CONVERT THE 10BIT VIDEO TO 8BIT USING X264, MKV, KEEPING ORIGINAL AUDIO STREAMS
  ## LOWER -CRF FOR BETTER QUALITY (18 IS GOOD BALANCE OF QUALITY/SIZE)
  ffmpeg -i "$video_file" -vcodec libx264 -crf 18 -acodec copy "$DIR/8bit/$VIDFILE.mkv" < /dev/null;

  ## MOVE 10BIT ORIGINAL TO SUBDIRECTORY FOR BACKUP
  printf "\n\ncreating subdirectory to backup original 10bit file : ($DIR/10bit) \n\n"
  mkdir -p "$DIR/10bit"
  mv "$video_file" "$DIR/10bit/"

  ## MOVE CONVERTED 8BIT FILE TO ORIGINAL DIRECTORY SO IT GETS PICKED UP BY MEDIA PLAYERS, ETC.
  printf "\n\nmoving converted 8bit video to original directory and cleaning up"
  mv "$DIR/8bit/$VIDFILE.mkv" "$DIR/"
  rm -rf "$DIR/8bit"

done < /tmp/10bit_vid_10_stripped.log


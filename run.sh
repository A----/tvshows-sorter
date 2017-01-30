#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
CONF_FILENAME=options.conf
CONF_FILE=$SCRIPT_DIR/$CONF_FILENAME

BOLD="\e[1m"
DIM="\e[2m"
LIGHT_RED="\e[91m"
LIGHT_CYAN="\e[96m"
LIGHT_GREEN="\e[92m"
LIGHT_YELLOW="\e[93m"
RESET="\e[0m"

function usage {
  read -r -d '' USAGE <<USAGE
${BOLD}Usage:${RESET}
  $0 -s <source_folder> -d <destination_folder> [-v] [-t] [-i]

${BOLD}Options:${RESET}
  * s: source folder
  * d: destination folder
  * v: add debug output
  * t: test/dry-run mode
  * i: all regular expressions will be case insensitive
  * h: prints this message

You can optionnally create a ${BOLD}$CONF_FILENAME${RESET} file alongside this script to provide
default values for those options.
USAGE

  if [[ -n "$2" ]]
  then
    read -r -d '' USAGE <<ERROR
$USAGE

${LIGHT_RED}Error: $2${RESET}
ERROR

  fi

  if [[ -z "$1" ]] || [[ "$1" -gt 1 ]]
  then
    >&2 echo -e "$USAGE"
    exit $1
  else
    echo -e "$USAGE"
    exit
  fi
}

COLS=${COLS-80}
function echo_right {
  CHR_COUNT=$(echo "$@" | tr -d '[:cntrl:]' )
  PAD=$(printf %-$(($COLS - ${#CHR_COUNT}))s " ")
  echo -e "$PAD$@"
}

if [[ -f "$CONF_FILE" ]]
then
  source "$CONF_FILE"
fi

while getopts ":hvtis:d:" OPT
do
  echo OPT: $OPT
  echo OPTARG: $OPTARG
  case $OPT in
    h)
      usage 1
      ;;
    v)
      VERBOSE=1
      ;;
    t)
      DRY_RUN=1
      ;;
    i)
      CASE_INSENSITIVE=1
      ;;
    s)
      SOURCE_FOLDER=$OPTARG
      ;;
    d)
      DESTINATION_FOLDER=$OPTARG
      ;;
    \?)
      usage 2 "Invalid options $OPTARG"
      ;;
    :)
      usage 2 "Option -$OPTARG requires an argument."
      ;;
  esac
done
shift $((OPTIND-1))

if [[ "$VERBOSE" ]]
then
  read -r -d '' CONFIGURATION <<CONFIGURATION
${BOLD}Configuration:${RESET}
  Source folder: ${LIGHT_CYAN}$SOURCE_FOLDER${RESET}
  Destination folder: ${LIGHT_CYAN}$DESTINATION_FOLDER${RESET}
CONFIGURATION

  echo -e "$CONFIGURATION"
  echo
fi

DEFAULT_FILE_REGEX='.*\.(mkv|avi)'
DEFAULT_FILENAME_REGEXS=(
  '([^/]+)S([0-9]+)E[0-9+]+'
  '([^/]+)/S([0-9]+)E[0-9+]+'
)
DEFAULT_CLEANER_REGEX='[-._+/]'

if [[ "$CASE_INSENSITIVE" ]]
then
  shopt -s nocasematch
fi

find "$SOURCE_FOLDER" -type f -regextype posix-extended -regex "${FILE_REGEX-$DEFAULT_FILE_REGEX}" -print0 | while IFS= read -r -d '' FILE
do
  FILENAME=$(basename "$FILE")
  echo $FILE

  FOUND=

  for FILENAME_REGEX in ${FILENAME_REGEXS-${DEFAULT_FILENAME_REGEXS[@]}}
  do
    if [[ "$FILE" =~ $FILENAME_REGEX ]]
    then
      DIRTY_SHOW_NAME="${BASH_REMATCH[1]}"
      DIRTY_SHOW_NAME="${DIRTY_SHOW_NAME//${CLEANER_REGEX-$DEFAULT_CLEANER_REGEX}/ }"
      DIRTY_SHOW_NAME="${DIRTY_SHOW_NAME%"${DIRTY_SHOW_NAME##*[![:space:]]}"}"
      SHOW_NAME=$DIRTY_SHOW_NAME
      DIRTY_SEASON_NUMBER="${BASH_REMATCH[2]}"
      SEASON_NUMBER=$(printf '%02d' "${DIRTY_SEASON_NUMBER#0}")

      SEASON_FOLDER="$SHOW_NAME/Season $SEASON_NUMBER"
      DESTINATION_PATH="$DESTINATION_FOLDER/$SEASON_FOLDER"
      DESTINATION_FILE="$DESTINATION_PATH/$FILENAME"

      if [[ -e "$DESTINATION_FILE" ]]
      then
        echo_right "${LIGHT_CYAN}Already exists${RESET}"
      else
        if [[ ! -d "$DESTINATION_PATH" ]]
        then
          [[ ! "$DRY_RUN" ]] && mkdir -p "$DESTINATION_PATH"
          echo_right "Directory ${BOLD}$SEASON_FOLDER${RESET} ${LIGHT_GREEN}created${RESET}"
        fi

        [[ ! "$DRY_RUN" ]] && ln -rs "$FILE" "$DESTINATION_FILE"
        echo_right "${LIGHT_GREEN}Linked${RESET} in ${BOLD}$SEASON_FOLDER${RESET}"
      fi

      FOUND=1
      break
    fi
  done

  [[ ! "$FOUND" ]] && echo_right "${LIGHT_YELLOW}Ignored${RESET}"
done

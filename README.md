# tvshows-sorter

Kodi has quite a strict policy on [file naming](http://kodi.wiki/view/naming_video_files/TV_shows), forcing TV shows to have their own folders. This script creates (symbolic) links in another folder.

## Usage

`./run.sh -s <source_folder> -d <destination_folder> [-v] [-t] [-i]`

Options:
* `s`: source folder
* `d`: destination folder
* `v`: add debug output
* `t`: test/dry-run mode
* `i`: all regular expressions will be case insensitive
* `h`: prints this message

You can optionnally create a options.conf file alongside this script to provide
default values for those options.

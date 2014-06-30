#!/bin/bash
#
# Copyright (C) 2014, Tjerk Ameel
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


##### Constants
APP_NAME=$0
OSX_VERSION=$(sw_vers -productVersion)
SEPERATOR="---------------------------------"

#####
use_growl=0
directories=()
file_pattern="*.log"

##### Functions
function usage
{
    echo "Usage: ${APP_NAME} [-g][-h] [-p file_pattern] folder(s)"
}

function cleanUp
{
    printf "\nStopping %s...\n" "${APP_NAME}"
    # Stops ALL background processes
    kill 0
}

function checkOS
{
    # The bash extended test command can compare dotted version numbers.
    # shellcheck disable=SC2072
    if [[ ${OSX_VERSION} < 10.8 ]] && [ ${use_growl} -eq 0 ]; then
        echo "Error: You need at least OSX 10.8 or higher to run this script without the --growl option."
        exit 1
    fi
}

function checkSoftware
{
    # https://github.com/alloy/terminal-notifier
    if  ! which -s terminal-notifier && [ ${use_growl} -eq 0 ]; then
        echo "Attempting to install 'terminal-notifier'..."
        # Lets try to install terminal-notifier
        sudo gem install terminal-notifier

        # Check to see if installation succeeded
        if  ! which -s terminal-notifier; then
            echo "Error: Could not install 'terminal-notifier'!"
            echo "For manual installation see: https://github.com/alloy/terminal-notifier"
            exit 1
        else
            printf "Installation succesfull! \n--\n"
            terminal-notifier -message "Successfully installed 'terminal-notifier'!"
        fi
    fi

    if  ! which -s growlnotify && [ ${use_growl} -eq 1 ]; then
        echo "You need to download and install 'growlnotify' first!"
        printf "URL: http://growl.info/downloads \n"
        printf "Open download page now? \n"
        select result in Yes No
        do
            case ${result} in
                Yes )   open "http://growl.info/downloads";
                        break;;
                No )    break;;
            esac
        done
        exit 1
    fi

    # https://github.com/alandipert/fswatch
    if  ! which -s fswatch; then
        # TODO check if brew is installed first, if not:
        # ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
        echo "Attempting to install 'fswatch'..."
        brew install fswatch
        if  ! which -s fswatch; then
            echo "Error: Could not install 'fswatch'!"
            exit 1
        else
            printf "Installation succesfull! \n--\n"
        fi
    fi
}

function recievedFSEvent
{
    event="$@"

    # Listen for file creation
    if echo "${event}" | grep -i "Created" | grep -i "IsFile" > /dev/null ; then
        # Make sure the file matches the desired pattern
        for directory in "${directories[@]}"
        do
            # We need globbing: do not double quote ${file_pattern}
            # shellcheck disable=SC2086
            find ${directory} -iname ${file_pattern} | while IFS=$'\n' read -r file
            do
                if [ "${event/$file}" != "${event}" ] ; then
                    # Found a match -> start monitoring
                    trackFile 999 "${file}"
                fi
            done
        done
    fi
}

function trackFolder
{
    directory=$1
    echo "${directory}/${file_pattern}"
    # We need globbing: do not double quote ${file_pattern}
    # shellcheck disable=SC2086
    trackFile 0 "${directory}/"${file_pattern}
}

function trackFile
{
    initial_number_of_lines=$1
    shift

    for file in "$@"
    do
        if [ ! -f "${file}" ]
        then
            echo "Warning: No files to track in '${file}'"
        else
            echo "--> Tracking: '${file}'"
            # shellcheck disable=SC1004,SC2016
            tail -n "${initial_number_of_lines}" -f "${file}" | php -r '
                $path = trim($argv[1]);
                $app_name = trim($argv[2]);
                $use_growl = $argv[3];

                stream_set_blocking(STDIN, 0);
                $filename = escapeshellarg(basename($path));
                $realpath = realpath($path);

                // Loop until we get `end-of-file` from the stream.
                // This keeps the php processes from running after the tail command have been killed.
                while (!feof(STDIN)) {
                  sleep(1);
                  $s = "";
                  while (($line = fgets(STDIN)) !== false) {
                    $s.=$line;
                  }
                  if ($s != ""){
                    $message = escapeshellarg(trim($s));

                    if($use_growl){
                        // Need to escape urlencode spaces in filename for terminal-notifier
                        $realpath = str_replace(" ", "%20", $realpath);

                        // Requires: growlnotify (http://growl.info/downloads)
                        shell_exec("growlnotify \
                            --sticky \
                            --name $app_name \
                            --title $filename \
                            --priority 0 \
                            --message $message \
                            --url \"file://$realpath\" \
                            --appIcon com.apple.Console \
                        ");
                    }else{
                        // Need to escape spaces in filename for terminal-notifier
                        $realpath = str_replace(" ", "\ ", $realpath);

                        // Requires: terminal-notifier (https://github.com/alloy/terminal-notifier)
                        shell_exec("terminal-notifier \
                            -sound Basso \
                            -message $message \
                            -title $filename \
                            -sender com.apple.Console \
                            -execute \"open -b com.apple.Console $realpath;\" /
                        ");
                    }

                  }
                };
                ' "${file}" "${APP_NAME}" "${use_growl}" &
        fi
    done
}

##### Main
# Process options
for var in "$@"
do
    case ${var} in
        -p | --file-pattern )   shift
                                file_pattern=$1
                                shift
                                ;;
        -g | --growl )          use_growl=1
                                shift
                                echo "Using Growl for notifications..."
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
done

# Assume that the rest of the arguments are the directory/directories
for directory in "$@"
do
    # `%/` strips trailing slash from directory if present.
    directories=("${directories[@]}" "${directory%/}")
done

# Need to check for valid OS after the options have been set!
checkOS
checkSoftware

# Check for required arguments
if [ $# -eq 0 ]
then
    echo "Error: Please provide the path of folder you want to monitor."
    usage
    exit 1
fi

# When this script exits, exit all background processes also.
trap cleanUp EXIT

# Start tracking existing files
printf "%s\n%s\n%s\n" "${SEPERATOR}" "Start tracking existing files..." "${SEPERATOR}"
for directory in "${directories[@]}"
do
    if [ ! -d "$directory" ]
    then
        echo "Error: '${directory}' is not a valid directory."
        usage
        exit 1
    else
        trackFolder "${directory}"
    fi
done

# listen for newly created files
printf "%s\n%s\n%s\n" "${SEPERATOR}" "Start watching for new files..." "${SEPERATOR}"
fswatch -0 -x "$@" | while read -d '' event
do
    recievedFSEvent "${event}"
done

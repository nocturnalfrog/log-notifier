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

#####
use_growl=0
file_pattern=""

##### Functions
function usage
{
    echo "Usage: ${APP_NAME} [-g][-h] -f file_pattern folder(s)"
}

function cleanUp
{
    echo "Stopping ${APP_NAME}..."
    # TODO check if this is still working
    if [ ! -z "$(jobs -p)" ]; then
        echo "Exiting all background proceses..."
        kill $(jobs -p);
    fi
}

function checkOS
{
    # The bash extended test command can compare dotted version numbers.
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
            echo "Installation succesfull! \n --"
            terminal-notifier -message "Successfully installed 'terminal-notifier'!"
        fi
    fi

    if  ! which -s growlnotify && [ ${use_growl} -eq 1 ]; then
        echo "You need to download and install 'growlnotify' first! (http://growl.info/downloads)"
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
            echo "Installation succesfull! \n --"
        fi
    fi
}

function recievedFSEvent
{
    # TODO handle spaces in file path!!
    filename=$1
    shift
    event_flags=$@
    echo ${event_flags}

    # Listen for file creation
    if echo ${event_flags} | grep -q "Created" --exclude "IsDir" > /dev/null ; then
        # TODO Require a file pattern to match
        trackFile 999 "${filename}"
        echo "Started Monitoring: ${filename}"
    fi
    echo "recievedFSEvent: ${filename} (${event_flags})"
    echo "----"
}

function trackFolder
{
    path=$1
    echo "Tracking: ${path}${file_pattern}"
    trackFile 0 ${path}${file_pattern}
}

function trackFile
{
    initial_number_of_lines=$1
    shift

    for path in "$@"
    do
        echo "Tracking file: '${path}'"
        if [ ! -f "$path" ]
        then
            echo "Warning: Found no files to track in '${path}'"
        else
            echo "Tracking changes to '${path}'"
            tail -n ${initial_number_of_lines} -f "${path}" | php -r '
                array_shift($argv);
                // Escapce spaces in file path
                $path = implode("\ ", $argv);

                stream_set_blocking(STDIN, 0);
                $filename = basename($path);
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

                    if('${use_growl}'){
                        // Requires: growlnotify (http://growl.info/downloads)
                        shell_exec("growlnotify \
                            --sticky \
                            --name '${APP_NAME}' \
                            --title $filename \
                            --priority 0 \
                            --message $message \
                            --url file://$realpath\
                            --appIcon com.apple.Console\
                        ");
                    }else{
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
                ' ${path} &
        fi
    done
}

##### Main
# Process options
for var in "$@"
do
    case ${var} in
        -f | --file-pattern )   shift
                                file_pattern=$1
                                shift
                                ;;
        -g | --growl )          use_growl=1
                                shift
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
done

# Need to check for valid OS after the options have been set!
checkOS
checkSoftware

# Check for required arguments
if [ -z "${file_pattern}" ]; then
    echo "Error: Please provide a file pattern"
    usage
    exit 1
fi

if [ $# -eq 0 ]
then
    echo "Error: Please provide the path of folder you want to monitor."
    usage
    exit 1
fi

# When this script exits, exit all background processes also.
trap cleanUp EXIT

# Start tracking existing files
for path in "$@"
do
    if [ ! -d "$path" ]
    then
        echo "Error: '${path}' is not a valid directory."
        usage
        exit 1
    else
        trackFolder "${path}"
    fi
done

# listen for newly created files
fswatch -0 -xr $@ | while read -d '' event
do
    recievedFSEvent ${event}
done &


# wait ... until CTRL+C
echo "waiting for file changes..."
# Make sure the app doesn't quit when there are no files to track on startup
while true; do read x; done
wait
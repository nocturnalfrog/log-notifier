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
APP_NAME="LogTracker"

##### Functions

function usage
{
    echo "Usage: logtracker [-g|--growl][-h|--help] file(s)"
}

function cleanUp
{
    echo "Stopping ${APP_NAME}..."

    if [ ! -z '$(jobs -p)' ]; then
        echo "Exiting all background proceses..."
        kill $(jobs -p);
    fi
}


##### Main
use_growl=0

count=0
params=( "$@" )
for var in "$@"
do
    case ${var} in
        -g | --growl )          use_growl=1
                                # Remove argument
                                unset params[${count}]
                                set -- "${params[@]}"
                                ;;
        -h | --help )           usage
                                exit
                                ;;
    esac
    count=$((count+1))
done

# Check for required arguments
if [ $# -eq 0 ]
then
    echo "Error: Please provide the path of the file(s) you want to monitor."
    echo $(usage)
    exit 1
fi

# When this script exits, exit all background processes also.
trap cleanUp EXIT

# Iterate the given file names.
for path in "$@"
do
    if [ ! -f "$path" ]
    then
        if [ "$path" = "" ]; then
            echo "Error: Please provide the path of the file you want to monitor."
        else
            echo "Error: '${path}' not found."
        fi
        exit 1
    else
        echo "Tracking changes to '${path}'"

        tail -n 0 -f ${path} | php -r '
        stream_set_blocking(STDIN, 0);
        $filename = basename("'${path}'");
        $realpath = realpath("'${path}'");
        while (true) {
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
        };' &
    fi
done

# wait ... until CTRL+C
wait


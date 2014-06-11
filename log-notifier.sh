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


# Constants
here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
appname="LogTracker"
iconpath="${here}/../img/bg-magento-dev.png";


# Check for required arguments
if [ $# -eq 0 ]
then
    echo "Error: Please provide the path of the file(s) you want to monitor."
    exit 1
fi

# When this exits, exit all back ground process also.
trap 'kill $(jobs -p);' EXIT

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
        echo "Stopping ${appname}..."
        exit 1
    else
        echo "Tracking changes to '${path}'"
#        echo $(pwd)"/${path}"
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
            // Requires: growlnotify (http://growl.info/downloads)
            shell_exec("growlnotify --sticky -n '${appname}' -t $filename -p 0 -m $message --image '${iconpath}'");

            // Requires: terminal-notifier (https://github.com/alloy/terminal-notifier)
            shell_exec("terminal-notifier -sound Basso -message $message -title $filename -sender com.apple.Console -execute \"open -b com.apple.Console $realpath;\" ");
          }
        };' &
    fi
done

# wait ... until CTRL+C
wait
Log Notifier
============
Watches for new data in your log files and displays this data either via `Notification Center` or `Growl`.

Your log files don't need to exist when you start `log-notifier`, it will automatically detect
and monitor new files provided the match the `--file-pattern` option.

Installation
------------
You can install log-notifier from [Homebrew](http://mxcl.github.com/homebrew/) using:

    $ brew install log-notifier

Dependencies
------------
(Don't worry about the required dependencies, [Homebrew](http://mxcl.github.com/homebrew/) installs these for you.)
###Required:

* [fswatch](https://github.com/alandipert/fswatch) is used for detecting new files.
* [terminal-notifier](https://github.com/alloy/terminal-notifier) is needed to display notifications in `Notification Center`.

###Optional:
* `growlnotify` is required if you want the notifications to be displayed by `Growl` (see the `--growl` under options).
You must install Growl on your own. You can learn more about Growl and see installation instructions at [growl.info](http://growl.info).


Usage
-----
    Usage: log-notifier [-h] [-g] [-p file_pattern] path_to_folder(s)

    Options:
        -h, --help            Show this message.
        -g, --growl           Use Growl instead of Notification Center for notifications.
        -p, --file-pattern    Use a specific file pattern to monitor. (defaults to '*.log')

Example Usage
-------------
Receive notifications via `Notification Center` when new entries are added to `*.log` files in the `/path/to/log/folder/` folder:

    $ log-notifier /path/to/log/folder/

Receive notifications via `Growl` when new entries are added to the `error.log` in the `/path/to/log/folder/` folder:

    $ log-notifier --growl --file-pattern "error.log" /path/to/log/folder/

Receive notifications via `Growl` when new entries are added to  `*.log` files in any `/path/to/vhosts/*/log/` folder:

    $ log-notifier --growl  /path/to/vhosts/*/log/

Don't like Homebrew? That's okay.
---------------------------------
Included in the repo is a makefile that allows you to install/uninstall without Homebrew.
(Please note that you will have to install the required dependencies manually.)

    $ make install
    $ make uninstall


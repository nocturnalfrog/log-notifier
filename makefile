install:
	# create a symlink of log-notifier in users bin folder
	ln -s $(CURDIR)/log-notifier /usr/local/bin/log-notifier

uninstall:
	# remove symlink
	rm /usr/local/bin/log-notifier
require 'formula'

class LogNotifier < Formula
  homepage 'https://github.com/nocturnalfrog/log-notifier'
  head 'https://github.com/nocturnalfrog/log-notifier.git'
  url 'https://github.com/nocturnalfrog/log-notifier/archive/v0.1.tar.gz'
  sha1 'dc698a295849ec4294607632ab801084027f66d2'

  def install
    bin.install 'log-notifier'
  end

  # Adding dependencies
  depends_on :macos => :lion # Needs at least Mac OS X "Lion" aka. 10.7.
  depends_on "terminal-notifier"
  depends_on "fswatch"

  test do
    system bin/"log-notifier", "--test"
  end
end

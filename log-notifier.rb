require "formula"

class LogNotifier < Formula
  homepage "https://github.com/nocturnalfrog/log-notifier"
  head "https://github.com/nocturnalfrog/log-notifier.git"
  url "https://github.com/nocturnalfrog/log-notifier/archive/v0.4.tar.gz"
  sha1 "7d867897bfeb21d8cb02abf353c74a55623f0a74"

  def install
    bin.install "log-notifier"
  end

  # Adding dependencies
  depends_on :macos => :lion # Needs at least Mac OS X "Lion" aka. 10.7.
  depends_on "terminal-notifier"
  depends_on "fswatch"

  test do
    system bin/"log-notifier", "--test"
  end
end

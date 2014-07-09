require "formula"

class LogNotifier < Formula
  homepage "https://github.com/nocturnalfrog/log-notifier"
  head "https://github.com/nocturnalfrog/log-notifier.git"
  url "https://github.com/nocturnalfrog/log-notifier/archive/v0.3.1.tar.gz"
  sha1 "e2567257a6bfb492ce860235ea022863c83a3c74"

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

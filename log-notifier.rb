require "formula"

class LogNotifier < Formula
  homepage "https://github.com/nocturnalfrog/log-notifier"
  head "https://github.com/nocturnalfrog/log-notifier.git"
  url "https://github.com/nocturnalfrog/log-notifier/archive/v0.4.tar.gz"
  sha256 "eeae5c2e1a771dc447640da7056efcf84aa194911568fe66db170dd5588a9fd4"

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

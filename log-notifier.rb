require 'formula'

class LogNotifier < Formula
  homepage 'https://github.com/nocturnalfrog/log-notifier'
  head 'https://github.com/nocturnalfrog/log-notifier.git'
  url 'https://github.com/nocturnalfrog/log-notifier/archive/v0.1.tar.gz'
  sha1 'dc698a295849ec4294607632ab801084027f66d2'

  def install
    bin.install 'log-notifier'
  end
end
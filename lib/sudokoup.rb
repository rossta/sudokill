$LOAD_PATH << File.expand_path(File.dirname(__FILE__)) + "/../vendor/addressable/lib"
$LOAD_PATH << File.expand_path(File.dirname(__FILE__)) + "/../vendor/em-websocket/lib"

require "rubygems"
require "socket"
require "eventmachine"
require "addressable/uri"
require "em-websocket"

%w[ server board move logger client ].each do |file|
  require "sudokoup/#{file}"
end

%w[ client web_socket ].each do |file|
  require "sudokoup/connection/#{file}"
end

def log(message, name = "Server")
  Sudokoup::Logger.log "%-10s>> #{message}" % name
end

module Sudokoup
CONFIG_1 = <<-TXT
7 0 5 0 0 0 2 9 4
0 0 1 2 0 6 0 0 0
0 0 0 0 0 0 0 0 7
9 0 4 5 0 0 0 2 0
0 0 7 3 6 2 1 0 0
0 2 0 0 0 1 7 0 8
1 0 0 0 9 0 0 0 0
0 0 0 7 0 5 9 0 0
5 3 9 0 0 0 8 0 2
TXT

CONFIG_2 = <<-TXT
8 0 0 0 0 4 0 0 1
0 0 0 0 0 0 0 0 0
0 3 2 0 5 0 4 9 0
0 0 5 0 0 8 3 0 0
3 0 0 6 1 9 0 0 5
0 0 1 3 0 0 6 0 0
0 8 4 0 7 0 1 2 0
0 0 0 0 0 0 0 0 0
7 0 0 2 0 0 0 0 4
TXT
end

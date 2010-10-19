$LOAD_PATH << File.expand_path(File.dirname(__FILE__)) + "/../vendor/"

require "rubygems"
require "socket"
require "eventmachine"
require "em-websocket"

%w[ proxy web_socket ].each do |file|
  require "sudokl/#{file}"
end


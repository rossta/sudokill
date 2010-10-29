$LOAD_PATH << File.expand_path(File.dirname(__FILE__)) + "/../vendor/em-websocket/lib"

require "rubygems"
require "socket"
require "eventmachine"
require "em-websocket"

%w[ server board client_handler view_handler ].each do |file|
  require "sudokl/app/#{file}"
end

%w[ base ].each do |file|
  require "sudokl/client/#{file}"
end

%w[ proxy web_socket controller ].each do |file|
  require "sudokl/view/#{file}"
end



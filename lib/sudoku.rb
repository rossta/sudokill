$LOAD_PATH << File.expand_path(File.dirname(__FILE__)) + "/../vendor/"

require "rubygems"
require "em-websocket"

%w[ server ].each do |file|
  require "sudoku/#{file}"
end

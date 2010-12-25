$LOAD_PATH << File.expand_path(File.dirname(__FILE__)) + "/../vendor/addressable/lib"
$LOAD_PATH << File.expand_path(File.dirname(__FILE__)) + "/../vendor/em-websocket/lib"

require "rubygems"
require "socket"
require "eventmachine"
require "addressable/uri"
require "em-websocket"

%w[ state_machine timer server controller board move dispatch logger game web_server messaging ].each { |file| require "sudokill/#{file}" }

%w[ client_connection socket web_socket ].each { |file| require "sudokill/client/#{file}" }

%w[ naive ].each { |file| require "sudokill/player/#{file}" }

module Sudokill
  @@env = :development
  def self.env=(env)
    @@env = env
  end

  def self.env
    @@env
  end

  def self.run(opts = {})
    require 'yaml'
    config = YAML.load_file('config/server.yml')[opts[:env].to_s]
    
    Sudokill::Server.start(
      :env  => opts[:env],
      :host => config['host'],
      :port => config['port']['socket'],
      :ws_port => config['port']['websocket'],
      :http_port => config['port']['http'],
      :size => 2,
      :instances => config['instances'],
      :max_time_socket => config['max_time']['socket'],
      :max_time_websocket => config['max_time']['websocket']
    )
  end
end

def log(message, name = "Server")
  Sudokill::Logger.log "%-10s>> #{message}" % name
end
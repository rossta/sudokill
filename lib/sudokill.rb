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
  def self.start!(script, env, opts = {})
    require 'yaml'
    config = YAML.load_file('config/server.yml')[env.to_s]
    command = []
    command << ["LOG=1"] if opts[:background]
    command << ["WEB=1"] if opts[:web]
    command << ["script/#{script.to_s}"]
    command << config['host']
    command << config['port']['socket'] unless opts[:web] == :only
    command << config['port']['websocket']
    command << config['port']['http'] if opts[:web]
    command << env.to_s
    command << config['instances']
    command << '&' if opts[:background]
    system command.join(" ")
  end
end

def log(message, name = "Server")
  Sudokill::Logger.log "%-10s>> #{message}" % name
end
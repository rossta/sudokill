require "erb"
require 'sinatra/base'

module Sudokill
  class WebServer < Sinatra::Base
    enable :run, :logging, :dump_errors, :raise_errors
    set :root, File.expand_path(File.dirname(__FILE__)) + "/../../"
    set :public, Proc.new { File.join(root, "public") }
    set :server, %w[thin mongrel webrick]

    configure :test do
      disable :logging, :dump_errors, :raise_errors, :run
    end

    get  %r{/sudokill|/} do
      puts "WS port: #{settings.ws_port}"
      erb :index
    end

  end
end

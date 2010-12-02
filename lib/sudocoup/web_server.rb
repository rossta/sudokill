require 'sinatra/base'

module Sudocoup
  class WebServer < Sinatra::Base
    enable :run
    set :logging, false
    set :port, 45678
    set :root, File.expand_path(File.dirname(__FILE__)) + "/../../"
    set :public, Proc.new { File.join(root, "public") }
    set :server, %w[thin mongrel webrick]

    get  %r{/sudocoup|/} do
      return File.open("public/index.html")
    end

  end
end
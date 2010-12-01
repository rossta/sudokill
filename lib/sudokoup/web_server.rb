require 'sinatra/base'

module Sudokoup
  class WebServer < Sinatra::Base
    enable :run, :logging
    set :port, 45678
    set :root, File.expand_path(File.dirname(__FILE__)) + "/../../"
    set :public, Proc.new { File.join(root, "public") }

    get  %r{/sudokoup|/} do
      return File.open("public/index.html")
    end
  end
end

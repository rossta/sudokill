require 'rubygems'
require 'sinatra'

enable :run

set :port, 45678
set :root, File.dirname(__FILE__)
set :public, Proc.new { File.join(root, "public") }

configure :production do |c|
  puts "Supported browsers: Chrome Safari 3+ Firefox 3+"
  puts "Go to http://localhost:#{c.port}/sudokoup"
end

configure :development do |c|
  puts "Supported browsers: Chrome Safari 3+ Firefox 3+"
  puts "Go to http://localhost:#{c.port}/sudokoup"
end

get  %r{/sudokoup|/} do
  return File.open("public/index.html")
end


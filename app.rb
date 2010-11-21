require 'rubygems'
require 'sinatra'

enable :run

configure :production do |c|
  set :port, 45678
  puts "Supported browsers: Chrome Safari 3+ Firefox 3+"
  puts "Go to http://localhost:#{c.port}/sudokoup"
end

configure :development do |c|
  puts "Supported browsers: Chrome Safari 3+ Firefox 3+"
  puts "Go to http://localhost:#{c.port}/sudokoup"
end

get "/sudokoup" do
  return File.open("public/index.html")
end


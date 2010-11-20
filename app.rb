require 'rubygems'
require 'sinatra'

configure :production do
end

configure :development do
  puts "Go to http://localhost:4567/sudokoup"
  puts "Supported browsers: Chrome Safari 3+ Firefox 3+"
end

get "/sudokoup" do
  return File.open("public/index.html")
end


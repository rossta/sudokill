require "rubygems"
require "rake"
require "bundler/setup"

require 'rspec/core/rake_task'

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  # t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
end

begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'

  # local jasmine extensions
  load 'lib/tasks/jasmine.rake'

rescue LoadError
  task :jasmine do
    abort "Jasmine is not available. In order to run jasmine, you must: (sudo) gem install jasmine"
  end
end

desc 'Default: run specs.'
task :default => [:spec, "jasmine:ci"]

# require 'static_fm'
# load 'static_fm/tasks/static_fm.rake'
# require "rubygems"
# require "rake"
# require "bundler/setup"
# 
# require 'rspec/core/rake_task'
# 
# require "rubygems"
# require "bundler/setup"
# require 'ruby-debug'
# # lib_path = File.expand_path() + "/lib/"
# debugger  
# $LOAD_PATH << File.expand_path(__FILE__, "lib")
# # $LOAD_PATH << lib_path unless $LOAD_PATH.include? lib_path
# require "sudokill"
# 
# Dir.glob(File.join(lib_path, "sudokill", "tasks", "*.rake")).each do |rake_file|
#   load rake_file
# end
# 
# desc 'Default: run specs.'
# task :default => [:spec, "jasmine:headless"]
# 

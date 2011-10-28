require "rubygems"
require "rake"
require "bundler/setup"

require 'rspec/core/rake_task'

# desc "Run specs"
# RSpec::Core::RakeTask.new do |t|
#   # t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
#   # Put spec opts in a file named .rspec in root
# end

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
Dir.glob(File.join("lib", "sudokill", "tasks", "*.rake")).each do |rake_file|
  load rake_file
end
desc 'Default: run specs.'
task :default => [:spec, "jasmine:ci"]


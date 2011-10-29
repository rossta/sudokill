require "rubygems"
require "rake"
require "bundler/setup"

Dir.glob(File.join("lib", "sudokill", "tasks", "*.rake")).each do |rake_file|
  load rake_file
end
desc 'Default: run specs.'
task :default => [:spec, "jasmine:ci"]


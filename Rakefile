require "rubygems"
require "rake"

lib_path = File.expand_path(File.dirname(__FILE__)) + "/lib/"
$LOAD_PATH << lib_path unless $LOAD_PATH.include? lib_path
require "sudokill"

Dir.glob(File.join(lib_path, "sudokill", "tasks", "*.rake")).each do |rake_file|
  load rake_file
end

desc 'Default: run specs.'
task :default => [:spec, "jasmine:ci"]


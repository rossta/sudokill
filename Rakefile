require "rubygems"
require "rake"
require "bundler/setup"

dir = File.expand_path(File.dirname(__FILE__))
%W[ spec jasmine ].each do |rake|
  load File.join(dir, "lib", "sudokill", "tasks", "#{rake}.rake")
end

desc 'Default: run specs.'
task :default => [:spec, "jasmine:ci:phantomjs"]

require 'static_fm'
load 'static_fm/tasks/static_fm.rake'

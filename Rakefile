require "rubygems"
require "rake"
require "bundler/setup"

$:.push File.expand_path('../lib', __FILE__)

Dir.glob(File.join("lib", "sudokill", "tasks", "*.rake")).each do |rake_file|
  load rake_file
end
desc 'Default: run specs.'
task :default => [:spec, "jasmine:ci"]

task :travis do
  ["rspec spec", "rake jasmine:ci"].each do |cmd|
    puts "Starting to run #{cmd}..."
    system("export DISPLAY=:99.0 && bundle exec #{cmd}")
    raise "#{cmd} failed!" unless $?.exitstatus == 0
  end
end
require "rubygems"
require "rake"

lib_path = File.expand_path(File.dirname(__FILE__)) + "/lib/"
$LOAD_PATH << lib_path unless $LOAD_PATH.include? lib_path
require "sudokill"

namespace :sudokill do
  namespace :production do
    task :start do
      pid = fork do
        Signal.trap('HUP', 'IGNORE') # Don't die upon logout

        log = File.new("log/sudokill.log", "a+")
        log.sync = true
        STDOUT.reopen(log)
        STDERR.reopen(log)

        Sudokill.run(:env => :production)
      end
      File.open('tmp/production.pid', 'w') {|f| f.write pid }
      Process.detach(pid)
    end
    task :stop do
      pidfile ='tmp/production.pid'
      pid     = File.read(pidfile) if File.exist?(pidfile)
      if pid.nil?
        puts "No pid found in #{pidfile}. Was the server running?"
      else
        Process.kill 'TERM', pid.to_i
        File.delete(pidfile)
      end
    end
  end

  task :production do
    Rake::Task["sudokill:production:start"].execute
  end

  task :start do
    Sudokill.run(:env => :development)
  end

end
task :sudokill => "sudokill:start"

begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue LoadError
  warn "jasmine gem not available"
end

namespace :jasmine do
  desc "Run specs via commandline"
  task :headless do
    system("ruby spec/javascripts/support/jazz_money_runner.rb")
  end
end


# Get your spec rake tasks working in RSpec 2.0

require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
end

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end
require "rubygems"
require "rake"

lib_path = File.expand_path(File.dirname(__FILE__)) + "/lib/"
$LOAD_PATH << lib_path unless $LOAD_PATH.include? lib_path
require "sudokill"

namespace :sudokill do
  namespace :game do
    task :development do
      Sudokill.run(:env => :development)
    end
    task :production do
      log = File.new("log/sudokill.log", "a+")
      log.sync = true
      STDOUT.reopen(log)
      STDERR.reopen(log)

      Sudokill.run(:env => :production)
    end
  end
  task :game => "sudokill:game:development"
  task :development => "sudokill:game:development"

  task :production do
    Rake::Task["sudokill:game:production"].execute
  end

  task :stop do
    system 'ps ax|grep "rackup"|grep -v grep|awk "{print \$1}"|xargs kill -s TERM'
    system 'ps ax|grep "ruby script/web"|grep -v grep|awk "{print \$1}"|xargs kill -s TERM'
    system 'ps ax|grep "ruby script/server"|grep -v grep|awk "{print \$1}"|xargs kill -s TERM'
  end

end
task :sudokill => "sudokill:development"

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
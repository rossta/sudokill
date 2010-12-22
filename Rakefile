require "rubygems"
require "rake"

lib_path = File.expand_path(File.dirname(__FILE__)) + "/lib/"
$LOAD_PATH << lib_path unless $LOAD_PATH.include? lib_path
require "sudokill"

namespace :sudokill do
  namespace :game do
    task :development do
      Sudokill.start!(:server, :development)
    end
    task :production do
      Sudokill.start!(:server, :production, :background => true)
    end
  end
  task :game => "sudokill:game:development"

  namespace :web do
    task :development do
      Sudokill.start!(:web, :development, :web => :only, :background => true)
    end
    task :production do
      Sudokill.start!(:web, :production, :background => true, :web => :only)
    end
  end
  task :web => "sudokill:web:development"

  task :development => "sudokill:game:development"

  task :production do
    Rake::Task["sudokill:game:production"].execute
    Rake::Task["sudokill:web:production"].execute
  end

  task :stop do
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
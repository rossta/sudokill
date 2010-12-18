require "rubygems"
require "rake"

namespace :sudocoup do
  namespace :game do
    task :default do
      system "WEB=1 script/server"
    end
    task :production do
      system "LOG=1 script/server 0.0.0.0 44444 48080 &"
    end
  end

  namespace :web do
    task :default do
      system "script/web"
    end
    task :production do
      system "LOG=1 script/web &"
    end
  end
  task :web => "sudocoup:web:default"
  
  task :production do
    system "LOG=1 WEB=1 script/server 0.0.0.0 44444 48080"
  end
end
task :sudocoup => "sudocoup:game:default"

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
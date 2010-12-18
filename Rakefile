require "rubygems"
require "rake"

namespace :sudocoup do
  namespace :game do
    task :default do
      system "script/server"
    end
    task :production do
      system "LOG=1 script/server 0.0.0.0 44444 48080 &"
    end
  end
  task :game => "sudocoup:game:default"

  namespace :web do
    task :default do
      system "script/web"
    end
    task :production do
      system "LOG=1 script/web 0.0.0.0 45678 48080 &"
    end
  end
  task :web => "sudocoup:web:default"

  task :production do
    system "LOG=1 WEB=1 script/server 0.0.0.0 44444 48080 45678 &"
  end
end

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
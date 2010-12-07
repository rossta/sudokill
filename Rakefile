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

  namespace :web do
    task :default do
      system "script/web"
    end
    task :production do
      system "LOG=1 script/web &"
    end
  end
  task :web => "sudocoup:web:default"
end
task :sudocoup => "sudocoup:game:default"

begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue LoadError
  warn "jasmine gem not available"
end

require "rubygems"
require "rake"

namespace :sudocoup do
  namespace :game_server do
    task :default do
      system "script/server"
    end
  end

  namespace :web_server do
    task :default do
      system "script/web"
    end
  end
  task :web => "sudocoup:web_server:default"
end
task :sudocoup => "sudocoup:game_server:default"

begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue
  warn "jasmine gem not available"
end

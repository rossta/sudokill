require "rubygems"
require "rake"

namespace :sudokoup do
  namespace :watch do
    task :default do
      system "ruby app.rb"
    end
    task :production do
      # ruby app.rb [-h] [-x] [-e production] [-p linserv1.cims.nyu.edu] [-o 45678] [-s HANDLER]
      system "ruby app.rb -e production -o 45678"
    end
  end
  task :watch => "sudokoup:watch:default"
end

begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue
  warn "jasmine gem not available"
end

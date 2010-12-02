require "rubygems"
require "rake"

namespace :sudocoup do
  namespace :watch do
    task :default do
      system "ruby app.rb"
    end
    task :production do
      # ruby app.rb [-h] [-x] [-e production] [-o linserv1.cims.nyu.edu] [-p 45678] [-s HANDLER]
      system "ruby app.rb -e production -p 45678"
    end
  end
  task :watch => "sudocoup:watch:default"
end

begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue
  warn "jasmine gem not available"
end

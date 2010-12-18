require "rubygems"
require "rake"

namespace :sudocoup do
  def start(script, env, opts = {})
    require 'yaml'
    config = YAML.load_file('config/server.yml')[env.to_s]
    command = []
    command << ["LOG=1"] if opts[:background]
    command << ["WEB=1"] if opts[:web]
    command << ["script/#{script.to_s}"]
    command << config['host']
    command << config['port']['socket']
    command << config['port']['websocket']
    command << config['port']['http'] if opts[:web]
    command << '&' if opts[:background]
    command.join(" ")
  end

  namespace :game do
    task :development do
      system start(:server, :development)
    end
    task :production do
      system start(:server, :production, :background => true)
    end
  end
  task :game => "sudocoup:game:development"

  namespace :web do
    task :development do
      system start(:web, :development)
    end
    task :production do
      system start(:web, :production, :background => true)
    end
  end
  task :web => "sudocoup:web:development"

  task :production do
    system start(:server, :production, :background => true, :web => true)
  end

  task :stop do
    system 'ps ax|grep "ruby script/web"|grep -v grep|awk "{print \$1}"|xargs kill -s TERM'
    system 'ps ax|grep "ruby script/server"|grep -v grep|awk "{print \$1}"|xargs kill -s TERM'
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
require "rubygems"
require "rake"

namespace :sudokill do
  def start(script, env, opts = {})
    require 'yaml'
    config = YAML.load_file('config/server.yml')[env.to_s]
    command = []
    command << ["LOG=1"] if opts[:background]
    command << ["WEB=1"] if opts[:web]
    command << ["script/#{script.to_s}"]
    command << config['host']
    command << config['port']['socket'] unless opts[:web] == :only
    command << config['port']['websocket']
    command << config['port']['http'] if opts[:web]
    command << env.to_s
    command << config['instances']
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
  task :game => "sudokill:game:development"

  namespace :web do
    task :development do
      system start(:web, :development, :web => :only, :background => true)
    end
    task :production do
      system start(:web, :production, :background => true, :web => :only)
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
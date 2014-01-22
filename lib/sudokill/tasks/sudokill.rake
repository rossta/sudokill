require 'dotenv/tasks'

task :environment => :dotenv do
  require 'sudokill'
end

namespace :sudokill do
  namespace :production do
    task :start do
      app_root = File.expand_path('../../../../', __FILE__)
      pid = fork do
        Signal.trap('HUP', 'IGNORE') # Don't die upon logout

        log = File.new(File.join(app_root, 'log', 'sudokill.log'), "a+")
        log.sync = true
        STDOUT.reopen(log)
        STDERR.reopen(log)

        Sudokill.run(:env => :production)
      end
      File.open(File.join(app_root, 'pids', 'production.pid'), 'w') {|f| f.write pid }
      Process.detach(pid)
    end
    task :stop do
      app_root = File.expand_path('../../../../', __FILE__)
      pidfile = File.join(app_root, 'pids', 'production.pid')
      pid     = File.read(pidfile) if File.exist?(pidfile)
      if pid.nil?
        puts "No pid found in #{pidfile}. Was the server running?"
      else
        Process.kill 'TERM', pid.to_i
        File.delete(pidfile)
      end
    end
  end

  desc "start sudokill with production environment"
  task :production => :environment do
    Rake::Task["sudokill:production:start"].execute
  end

  task :start => :environment do
    Sudokill.run(:env => :development)
  end

end
task :sudokill => "sudokill:start"

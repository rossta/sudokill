namespace :sudokill do
  namespace :production do
    task :start do
      pid = fork do
        Signal.trap('HUP', 'IGNORE') # Don't die upon logout

        log = File.new("log/sudokill.log", "a+")
        log.sync = true
        STDOUT.reopen(log)
        STDERR.reopen(log)

        Sudokill.run(:env => :production)
      end
      File.open('tmp/production.pid', 'w') {|f| f.write pid }
      Process.detach(pid)
    end
    task :stop do
      pidfile ='tmp/production.pid'
      pid     = File.read(pidfile) if File.exist?(pidfile)
      if pid.nil?
        puts "No pid found in #{pidfile}. Was the server running?"
      else
        Process.kill 'TERM', pid.to_i
        File.delete(pidfile)
      end
    end
  end

  task :production do
    Rake::Task["sudokill:production:start"].execute
  end

  task :start do
    Sudokill.run(:env => :development)
  end

end
task :sudokill => "sudokill:start"

God.watch do |w|
  w.name = 'sudokill'
  w.start = "/var/www/apps/sudokill/current/bin/sudokill -p 45678 -t 44444 -w 8080 -e production -i 3"
  w.keepalive(:memory_max => 150.megabytes,
              :cpu_max => 50.percent)
end

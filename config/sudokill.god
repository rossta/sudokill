# $ god -c /var/www/apps/sudokill/current/config/sudokill.god -D
God.watch do |w|
  w.name = 'sudokill'
  w.dir = '/var/www/apps/sudokill/current'
  w.start = "bundle exec ./bin/sudokill --http=45678 --tcp=44444 --ws=8080 --environment=production --instances=3"
  w.keepalive(:memory_max => 150.megabytes,
              :cpu_max => 50.percent)
  w.stop_signal = 'KILL'
end

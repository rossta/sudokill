#! /usr/bin/env ruby

lib_path = File.expand_path(File.dirname(__FILE__)) + "/lib/"
$LOAD_PATH << lib_path unless $LOAD_PATH.include? lib_path

require 'rubygems'
require 'bundler'
Bundler.require(:default)
require 'sudokill'

# FileUtils.mkdir_p 'log' unless File.exists?('log')
# log = File.new("log/sudokill.log", "a+")
# log.sync = true
# $stdout.reopen(log)
# $stderr.reopen(log)

pid = fork do

  Signal.trap('HUP', 'IGNORE') {
    pidfile ='tmp/production.pid'
    pid     = File.read(pidfile) if File.exist?(pidfile)
    if pid.nil?
      puts "No pid found in #{pidfile}. Was the server running?"
    else
      Process.kill 'TERM', pid.to_i
      File.delete(pidfile)
    end
  }

  Sudokill.run(:env => :production)
end

File.open('tmp/production.pid', 'w') {|f| f.write pid }
Process.detach(pid)

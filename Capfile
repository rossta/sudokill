load 'deploy' if respond_to?(:namespace) # cap2 differentiator

set :application, "sudokill"
set :user,        "ross"

set :scm,         :git
set :repository,  "git@github.com:rossta/sudokill.git"
set :deploy_via,  :remote_cache
set :deploy_to,   "/var/www/apps/#{application}"

role :app, "173.45.242.10:5826"
role :web, "173.45.242.10:5826"
role :db,  "173.45.242.10:5826", :primary => true

set :runner, user
set :admin_runner, user

$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, '1.9.2-p290'        # Or whatever env you want it to run in.
set :rvm_type, :user

# Bundler
require 'bundler/capistrano'

namespace :deploy do
  task :start, :roles => [:web, :app] do
    # run "cd #{deploy_to}/current && nohup thin -C config/thin/production.yml -R config.ru start"
    run "cd #{deploy_to}/current && bundle exec rake sudokill:production"
  end
 
  task :stop, :roles => [:web, :app] do
    # run "cd #{deploy_to}/current && nohup thin -C config/thin/production.yml -R config.ru stop"
    run "cd #{deploy_to}/current && bundle exec rake sudokill:production:stop"
  end
 
  task :restart, :roles => [:web, :app] do
    deploy.stop
    deploy.start
  end
 
  # This will make sure that Capistrano doesn't try to run rake:migrate (this is not a Rails project!)
  task :cold do
    deploy.update
    deploy.start
  end
end

namespace :sudokill do
  task :log do
    run "cat #{deploy_to}/current/log/sudokill.log"
  end
end
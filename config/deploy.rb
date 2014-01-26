set :application, "sudokill"
set :user,        "root"

set :scm,         :git
set :repository,  "git@github.com:rossta/sudokill.git"
set :deploy_via,  :remote_cache
set :deploy_to,   "/var/www/apps/#{application}"
set :branch, "master"

role :app, "107.170.9.121"
role :web, "107.170.9.121"
role :db,  "107.170.9.121", :primary => true

set :runner, user
set :admin_runner, user

default_run_options[:pty] = true
set :ssh_options, { :forward_agent => true }

$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.
set :rvm_ruby_string, '1.9.3-p429'        # Or whatever env you want it to run in.
set :rvm_type, :user
set :rvm_autolibs_flag, "read-only"       # more info: rvm help autolibs

before 'deploy:setup', 'rvm:install_rvm'  # install/update RVM
before 'deploy:setup', 'rvm:install_ruby' # install Ruby and create gemset, OR:

after "deploy:update_code", "sudokill:symlink"

# Bundler
require 'bundler/capistrano'

namespace :deploy do
  task :reload, :roles => [:web, :app] do
    run "god load #{deploy_to}/current/config/sudokill.god"
  end

  task :restart, :roles => [:web, :app] do
    run "god restart sudokill"
  end

  # This will make sure that Capistrano doesn't try to run rake:migrate (this is not a Rails project!)
  task :cold do
    deploy.update
    deploy.restart
  end
end

namespace :sudokill do
  task :log do
    run "cat #{deploy_to}/current/log/sudokill.log"
  end

  task :symlink do
    run "ln -nfs #{shared_path}/log #{release_path}/log"
    run "ln -nfs #{shared_path}/pids #{release_path}/pids"
    run "ln -nfs #{shared_path}/.env #{release_path}/.env"
  end
end

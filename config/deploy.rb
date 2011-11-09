require './config/boot'
require 'airbrake/capistrano'
require 'capones_recipes/tasks/airbrake'

#Application
set :application, "katalog"
set :repository,  "git@github.com:CyTeam/katalog.git"

# Staging
set :stages, %w(production staging fallback)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

# Deployment
set :server, :passenger
set :user, "deployer"                               # The server's user for deploys

# Configuration
set :scm, :git
ssh_options[:forward_agent] = true
set :use_sudo, false
set :deploy_via, :remote_cache
set :git_enable_submodules, 1
set :copy_exclude, [".git", "spec"]

# Restart passenger
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

# Bundle install
require "bundler/capistrano"
after "bundle:install", "deploy:migrate"

# Clean up the releases after deploy.
after "deploy", "deploy:cleanup"

# Generate the aspell wordlist
before 'deploy:restart', 'raspell:generate'
namespace :raspell do
  desc 'Generates the aspell wordlist for the suggestions.'
  task :generate, :roles => :app, :except => { :no_release => true } do
    run "cd #{release_path} && /usr/bin/env RAILS_ENV=#{rails_env} bundle exec rake katalog:raspell:update"
  end
end
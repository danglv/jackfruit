# config valid only for current version of Capistrano
lock '3.4.0'

set :rvm_type, :system
set :rvm_ruby_version, 'ruby-2.2.2@rails422'
set :application, 'pedia'

set :repo_url, 'git@git.pedia.vn:tcs/jackfruit.git'
set :stages, %w[staging production]
set :default_stage, 'staging'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set :linked_files, fetch(:linked_files, []).push('config/mongoid.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')
set :linked_dirs, fetch(:linked_dirs, []) + %w{public/uploads public/avatars log tmp/pids tmp/cache}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3

namespace :sidekiq do
  task :quiet do
    on roles(:app) do
      # Horrible hack to get PID without having to use terrible PID files
      puts capture("kill -USR1 $(sudo initctl status sidekiq index=1 | grep /running | awk '{print $NF}') || :") 
    end
  end

  task :restart do
    on roles(:sidekiq), in: :groups, wait: 3 do
      execute :sudo, 'service sidekiq restart index=1'
    end
  end
end

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), :in => :sequence, wait: 3 do
      execute :service, 'unicorn upgrade'
    end
  end

  desc 'Clear cache'
  task :clear_cache do
    on roles(:app, :web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        execute :rake, 'tmp:cache:clear'
      end
    end
  end
end

namespace :assets do
  desc 'Get bower dependencies'
  task :get_bower_dependencies do
    on roles(:app, :web) do
      within release_path do
        execute :bower, 'install'
      end
    end
  end
end  

# after 'deploy:starting', 'sidekiq:quiet'
before 'deploy:assets:precompile', 'assets:get_bower_dependencies'
after 'deploy:publishing', 'deploy:restart'
after 'deploy:restart', 'deploy:clear_cache'
after 'deploy:reverted', 'sidekiq:restart'
after 'deploy:published', 'sidekiq:restart'

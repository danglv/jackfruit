namespace :db do
  namespace :test do
    task :load => :environment do
      Rake::Task["db:reset"].invoke
      load "#{Rails.root}/db/seed_test.rb"
    end
  end
end
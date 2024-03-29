source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# Mongoid
gem "mongoid", "~> 5.0.0"
gem "bson_ext"

# Haml
gem "haml-rails", "~> 0.9"
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
# Hogan.js
gem 'hogan_assets', group: :assets
gem 'haml', group: :assets
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
gem 'unicorn', :platforms => :ruby

# Use Capistrano for deployment
gem 'capistrano-rails', group: :development
gem 'capistrano-rvm', group: :development
gem 'capistrano3-unicorn', group: :development

# User Devise for manage user some gem below for social login
gem 'devise', '~> 3.4.1'
gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-facebook'
gem "omniauth-google-oauth2"

#sidekiq
gem 'sidekiq'
gem 'sinatra', :require => nil

#sidekiq-cron setup cron for sidekiq
# gem "sidekiq-cron", "~> 0.3.0"

# Image
gem 'carrierwave'
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem 'mini_magick', '~> 3.8.1'
gem "ImageResize"

# ElasticSearch
gem 'elasticsearch-rails'
gem 'elasticsearch-model'

# Rails Admin
gem 'rails_admin'
gem 'devise-i18n'
# Add permission
gem "cancan"

# net/http-digest_auth
gem 'net-http-digest_auth', '~> 1.4'

# Http request
gem 'rest-client', '~> 1.8.0'

# Spymaster - Tracking System
gem 'spymaster', git: 'git@git.pedia.vn:tcs/spymaster-gem.git', branch: 'master'

group :production do
  # Unicorn worker killer
  gem 'unicorn-worker-killer'
end

group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'selenium-webdriver', '~> 2.48.1'
  gem 'minitest-rails'
  gem 'minitest-rails-capybara'
  gem 'minitest-reporters'
  gem 'webmock'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem "rack_session_access"
end

gem 'pry', '~> 0.10.1'
gem 'pry-rails', '~> 0.3.4'
gem 'will_paginate_mongoid', '~> 2.0.1'

gem 'tzinfo-data', platforms: [:mingw, :mswin]

gem 'rack-cors', :require => 'rack/cors'

# serializer
gem 'active_model_serializers', '~> 0.9.3'

# Simple line icons
gem 'simple-line-icons-rails'
ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/rails/capybara'
require 'capybara/rails'
require "rack_session_access/capybara"

## Comment this when using Chrome/Firefox
# require 'capybara/poltergeist'
require 'minitest/reporters'
require 'webmock/minitest'

Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)
# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
# require "minitest/pride"

class ActiveSupport::TestCase

  Rails.application.routes.disable_clear_and_finalize = true
  Rails.application.routes.draw do
    get '/uploads/images/:path', to: redirect("https://pedia.vn/uploads/images/%{path}")
  end

  WebMock.disable_net_connect!(allow_localhost: true)

  # Rake::Task["db:test:prepare"].invoke
  # ActiveRecord::Migration.check_pending!
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all
  # Add more helper methods to be used by all tests here...

  ## Test with Firefox
  # Capybara.default_driver = :selenium

  # Test with Chrome/Chromium
  Capybara.register_driver :chrome do |app|
    client = Selenium::WebDriver::Remote::Http::Default.new
    client.timeout = 5 * 60 # Page load timeout in seconds
    Capybara::Selenium::Driver.new(app, {:browser => :chrome})
  end
  Capybara.default_driver = :chrome

  ## Test with phantomjs
  # Capybara.register_driver :poltergeist do |app|
  #   Capybara::Poltergeist::Driver.new(app,
  #     {
  #       js_errors: false,
  #       phantomjs_options:['--proxy-type=none'],
  #       timeout:180
  #     }
  #   )
  # end
  # Capybara.default_driver = :poltergeist

  Rake::Task["db:test:load"].invoke
end

class ActionController::TestCase
  include Devise::TestHelpers
end

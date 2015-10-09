require 'sidekiq'
require 'sidekiq/web'

# Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
#   [user, password] == ["admin", "topica.memo"]
# end

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://sgredis1.pedia.vn:6379/12', namespace: 'worker', network_timeout: 5}
  config.average_scheduled_poll_interval = 25

  # database_url = ENV['DATABASE_URL']

  # if database_url
  #   ENV['DATABASE_URL'] = "#{database_url}?pool=15"
  #   ActiveRecord::Base.establish_connection
  # end
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://sgredis1.pedia.vn:6379/12', namespace: 'worker', network_timeout: 5}
  config.average_scheduled_poll_interval = 25

  # # database_url = ENV['DATABASE_URL']
  
  # if database_url
  #   ENV['DATABASE_URL'] = "#{database_url}?pool=15"
  #   ActiveRecord::Base.establish_connection
  # end
end
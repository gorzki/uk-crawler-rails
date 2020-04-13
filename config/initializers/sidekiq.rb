sidekiq_config = {
  url: ENV['JOB_WORKER_URL']
}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end

Rails.application.routes.default_url_options = { host: 'localhost', port: '3000' }
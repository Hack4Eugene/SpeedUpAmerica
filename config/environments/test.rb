require 'lograge'
require 'logglier'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  #config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  config.lograge.enabled = true
  config.lograge.keep_original_rails_log = false
  config.lograge.formatter = Lograge::Formatters::Raw.new
  config.lograge.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
  loggly = Logglier.new("https://logs-01.loggly.com/inputs/"+ENV["LOGGLY_TOKEN"]+"/tag/speedupamerica-v1", :format => :json, threaded: true)
  config.lograge.logger.extend(ActiveSupport::Logger.broadcast(loggly))

  # add time and IP to lograge
  config.lograge.custom_options = lambda do |event|
    {
      env: Rails.env,
      remote_ip: event.payload[:remote_ip],
      user_agent: event.payload[:user_agent],
    }
  end

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Configure static file server for tests with Cache-Control for performance.
  config.serve_static_files   = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.action_controller.page_cache_directory = "#{Rails.root.to_s}/public/cache"

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Randomize the order test cases are executed.
  config.active_support.test_order = :random

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  
  #this enables iframe option for other 3rd party sites
  config.action_dispatch.default_headers = {
    'X-Frame-Options' => 'ALLOWALL'
  }

end

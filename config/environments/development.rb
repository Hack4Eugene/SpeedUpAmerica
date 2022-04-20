Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :info

  # Prepend all log lines with the following tags.
  #config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  #config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true
  config.action_controller.page_cache_directory = "#{Rails.root.to_s}/public/cache"

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true


  config.web_console.permissions = '172.19.0.1'
  # https://stackoverflow.com/questions/29417328/how-to-disable-cannot-render-console-from-on-rails

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  config.action_dispatch.default_headers = {
    'X-Frame-Options' => 'ALLOWALL'
  }
end

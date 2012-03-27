# Be sure to restart your server when you modify this file

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# This is because the aws-s3 gem is using the XML:: namespace instead of LIBXML::
require 'xml/libxml'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # dont specify gems here, use the gemfile with bundler, see: http://gembundler.com/

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :all ]

  # Add additional load paths for your own custom dirs
  # config.autoload_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :info

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = 'UTC'

  if ENV['RUNNING_AS_DAEMON'] == 'true'
    config.log_path = Rails.root+'log/delayed_job.log'
  end

  log_config = File.exists?(Rails.root+"config/logging.yml") && YAML.load_file(Rails.root+"config/logging.yml")[RAILS_ENV]
  if log_config
    opts = {}
    opts[:skip_thread_context] = true if log_config['log_context'] == false
    case log_config["logger"]
    when "syslog"
      require 'syslog_wrapper'
      log_config["app_ident"] ||= "canvas-lms"
      log_config["daemon_ident"] ||= "canvas-lms-daemon"
      facilities = 0
      (log_config["facilities"] || []).each do |facility|
        facilities |= Syslog.const_get "LOG_#{facility.to_s.upcase}"
      end
      ident = ENV['RUNNING_AS_DAEMON'] == 'true' ? log_config["daemon_ident"] : log_config["app_ident"]
      opts[:include_pid] = true if log_config["include_pid"] == true
      config.logger = RAILS_DEFAULT_LOGGER = SyslogWrapper.new(ident, facilities, opts)
    else
      require 'canvas/logger'
      log_level = ActiveSupport::BufferedLogger.const_get(config.log_level.to_s.upcase)
      config.logger = RAILS_DEFAULT_LOGGER = CanvasLogger.new(config.log_path, log_level, opts)
    end
  end

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  config.active_record.observers = :cacher

  config.autoload_paths += %W( #{RAILS_ROOT}/app/middleware #{RAILS_ROOT}/app/observers )

  config.middleware.insert_before('ActionController::ParamsParser', 'LoadAccount')
  config.middleware.insert_before('ActionController::ParamsParser', 'PreventNonMultipartParse')
  config.middleware.insert_before('ActionController::ParamsParser', "RequestContextGenerator")
  config.to_prepare do
    require_dependency 'canvas/plugins/default_plugins'
    ActiveSupport::JSON::Encoding.escape_html_entities_in_json = true
  end
end

# Extend any base classes, even gem classes
Dir.glob("#{RAILS_ROOT}/lib/ext/**/*.rb").each { |file| require file }

Canvas::Security.validate_encryption_key(ENV['UPDATE_ENCRYPTION_KEY_HASH'])

# Require parts of the lib that are interesting
%w(
  gradebook_csv_parser 
  workflow  
  file_splitter   
  gradebook_importer 
  auto_handle
  zip_extractor
).each { |f| require f }

require 'kaltura/kaltura_client_v3'

# tell Rails to use the native XML parser instead of REXML
ActiveSupport::XmlMini.backend = 'LibXML'

class NotImplemented < StandardError; end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      # We're in smart spawning mode, and need to make unique connections for this fork.
      Canvas.reconnect_redis
    end
  end
end

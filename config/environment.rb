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
  log_config = { 'logger' => 'rails', 'log_level' => 'debug' }.merge(log_config || {})
  opts = {}
  require 'canvas/logger'
  log_level = ActiveSupport::BufferedLogger.const_get(log_config['log_level'].to_s.upcase)
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
    config.logger.level = log_level
  else
    config.logger = RAILS_DEFAULT_LOGGER = CanvasLogger.new(config.log_path, log_level, opts)
  end

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  config.active_record.observers = [:cacher, :stream_item_cache]

  config.autoload_paths += %W(#{RAILS_ROOT}/app/middleware
                              #{RAILS_ROOT}/app/observers
                              #{RAILS_ROOT}/app/presenters)

  config.middleware.insert_after(ActionController::Base.session_store, 'SessionsTimeout')
  config.middleware.insert_before('ActionController::ParamsParser', 'LoadAccount')
  config.middleware.insert_before('ActionController::ParamsParser', 'StatsTiming')
  config.middleware.insert_before('ActionController::ParamsParser', 'PreventNonMultipartParse')
  config.middleware.insert_before('ActionController::ParamsParser', "RequestContextGenerator")
  config.to_prepare do
    require_dependency 'canvas/plugins/default_plugins'
    ActiveSupport::JSON::Encoding.escape_html_entities_in_json = true
  end

  # this patch is perfectly placed to go in as soon as the PostgreSQLAdapter
  # is required for the first time, but before it's actually used
  Rails::Initializer.class_eval do
    def initialize_database_with_postgresql_patches
      initialize_database_without_postgresql_patches

      if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        ActiveRecord::Base.class_eval do
          # Override to support custom postgresql connection parameters
          def self.postgresql_connection(config) # :nodoc:
            config = config.symbolize_keys
            config[:user] = config.delete(:username)

            if config.has_key?(:database)
              config[:dbname] = config.delete(:database)
            else
              raise ArgumentError, "No database specified. Missing argument: database."
            end

            # The postgres drivers don't allow the creation of an unconnected PGconn object,
            # so just pass a nil connection object for the time being.
            ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new(nil, logger, [config], config)
          end
        end

        # now let's try this again
        ActiveRecord::Base.establish_connection
      end
    end
    alias_method_chain :initialize_database, :postgresql_patches
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

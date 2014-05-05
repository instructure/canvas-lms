# this file is shared config between rails 2 and rails 3 (config/environment.rb and config/application.rb)
# it will get folded into config/application.rb once the transition to rails 3 is complete

# Settings in config/environments/* take precedence over those specified here.
# Application configuration should go into files in config/initializers
# -- all .rb files in that directory are automatically loaded.
# See Rails::Configuration for more options.

# Make Time.zone default to the specified zone, and make Active Record store time values
# in the database in UTC, and return them converted to the specified local zone.
# Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
config.time_zone = 'UTC'

log_config = File.exists?(Rails.root+"config/logging.yml") && YAML.load_file(Rails.root+"config/logging.yml")[CANVAS_RAILS2 ? RAILS_ENV : Rails.env]
log_config = { 'logger' => 'rails', 'log_level' => 'debug' }.merge(log_config || {})
opts = {}
require 'canvas_logger'
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
  config.logger = SyslogWrapper.new(ident, facilities, opts)
  config.logger.level = log_level
else
  log_path = CANVAS_RAILS2 ?
    config.log_path :
    config.paths['log'].first

  if ENV['RUNNING_AS_DAEMON'] == 'true'
    log_path = Rails.root+'log/delayed_job.log'
  end

  config.logger = CanvasLogger.new(log_path, log_level, opts)
end

RAILS_DEFAULT_LOGGER = config.logger if CANVAS_RAILS2

# RailsLTS configuration (doesn't apply to rails 3)
if CANVAS_RAILS2
  config.rails_lts_options = {
    disable_xml_parsing: true,
    # this is also taken care of below, since it defaults to false in rails3 as well
    escape_html_entities_in_json: true,
  }
end

# Activate observers that should always be running
config.active_record.observers = [:cacher, :stream_item_cache]

config.autoload_paths += %W(#{Rails.root}/app/middleware
                            #{Rails.root}/app/observers
                            #{Rails.root}/app/presenters
                            #{Rails.root}/app/services
                            #{Rails.root}/app/serializers
                            #{Rails.root}/app/presenters)

if CANVAS_RAILS2
  config.middleware.insert_before(ActionController::Base.session_store, 'LoadAccount')
  config.middleware.insert_before(ActionController::Base.session_store, 'SessionsTimeout')
else
  # we don't know what middleware to make SessionsTimeout follow until after
  # we've loaded config/initializers/session_store.rb
  initializer("extend_middleware_stack", after: "load_config_initializers") do |app|
    app.config.middleware.insert_before(config.session_store, 'LoadAccount')
    app.config.middleware.insert_before(config.session_store, 'SessionsTimeout')
  end
end

params_parser = CANVAS_RAILS2 ? 'ActionController::ParamsParser' : 'ActionDispatch::ParamsParser'
config.middleware.insert_before(params_parser, "RequestContextGenerator")
config.middleware.insert_before(params_parser, 'StatsTiming')
config.middleware.insert_before(params_parser, 'Canvas::RequestThrottle')
config.middleware.insert_before(params_parser, 'PreventNonMultipartParse')

config.to_prepare do
  require_dependency 'canvas/plugins/default_plugins'
  ActiveSupport::JSON::Encoding.escape_html_entities_in_json = true
end

# this patch is perfectly placed to go in as soon as the PostgreSQLAdapter
# is required for the first time, but before it's actually used
# XXX: Rails3
if CANVAS_RAILS2
  Rails::Initializer.class_eval do
    def initialize_database_with_postgresql_patches
      initialize_database_without_postgresql_patches

      if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        ActiveRecord::Base.class_eval do
          # Override to support custom postgresql connection parameters
          def self.postgresql_connection(config) # :nodoc:
            config = config.symbolize_keys
            config[:user] ||= config.delete(:username) if config.key?(:username)

            if config.has_key?(:database)
              config[:dbname] = config.delete(:database)
            else
              raise ArgumentError, "No database specified. Missing argument: database."
            end
            conn_params = config.slice(:host, :port, :dbname, :user, :password, :connect_timeout)

            # The postgres drivers don't allow the creation of an unconnected PGconn object,
            # so just pass a nil connection object for the time being.
            ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new(nil, logger, [conn_params], config)
          end
        end

        # now let's try this again
        ActiveRecord::Base.establish_connection
      end
    end
    alias_method_chain :initialize_database, :postgresql_patches
  end
end

# We need to make sure that safe_yaml is loaded *after* the YAML engine
# is switched to Syck (which DelayedJob needs for now). Otherwise we
# won't have access to (safe|unsafe)_load.
require 'yaml'
if RUBY_VERSION >= '2.0.0'
  require 'syck'
end
YAML::ENGINE.yamler = 'syck' if defined?(YAML::ENGINE)
require 'safe_yaml'
YAML.enable_symbol_parsing!
# We don't need to be reminded that safe loads are being used everywhere.
SafeYAML::OPTIONS[:suppress_warnings] = true

# This tag whitelist is syck specific. We'll need to tweak it when we upgrade to psych.
# See the tests in spec/lib/safe_yaml_spec.rb
YAML.whitelist.add(*%w[
  tag:ruby.yaml.org,2002:symbol
  tag:yaml.org,2002:map:HashWithIndifferentAccess
  tag:yaml.org,2002:map:ActiveSupport::HashWithIndifferentAccess
  tag:ruby.yaml.org,2002:object:OpenStruct
  tag:ruby.yaml.org,2002:object:Scribd::Document
  tag:ruby.yaml.org,2002:object:Mime::Type
  tag:ruby.yaml.org,2002:object:URI::HTTP
  tag:ruby.yaml.org,2002:object:URI::HTTPS
  tag:ruby.yaml.org,2002:object:OpenObject
])
YAML.whitelist.add('tag:ruby.yaml.org,2002:object:Class') { |classname| Canvas::Migration.valid_converter_classes.include?(classname) }

# Extend any base classes, even gem classes
Dir.glob("#{Rails.root}/lib/ext/**/*.rb").each { |file| require file }

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

if defined?(PhusionPassenger)
 PhusionPassenger.on_event(:after_installing_signal_handlers) do
  Canvas::Reloader.trap_signal
 end
else
  config.to_prepare do
    Canvas::Reloader.trap_signal
  end
end

# don't wrap fields with errors with a <div class="fieldWithErrors" />,
# since that could leak information (e.g. valid vs invalid username on
# login page)
config.action_view.field_error_proc = Proc.new { |html_tag, instance| html_tag }

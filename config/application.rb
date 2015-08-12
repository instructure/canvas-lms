# Put this in config/application.rb
require File.expand_path('../boot', __FILE__)

unless CANVAS_RAILS3

  # Yes, it doesn't seem DRY to list these both in the if and else
  # but this used to be "require 'rails/all'" which included sprockets.
  # I needed to explicitly opt-out of sprockets but since I'm not sure
  # about the other frameworks, I left this so it would be exactly the same
  # as "require 'rails/all'" but without sprockets--even though it is a little
  # different then the rails 3 else block. If the difference is not intended,
  # they can be pulled out of the if/else
  require "active_record/railtie"
  require "action_controller/railtie"
  require "action_mailer/railtie"
  # require "sprockets/railtie" # Do not enable the Rails Asset Pipeline
  require "rails/test_unit/railtie"

  Bundler.require(*Rails.groups)
else
  require "active_record/railtie"
  require "action_controller/railtie"
  require "action_mailer/railtie"
  require "active_resource/railtie"
  Bundler.require(:default, Rails.env) if defined?(Bundler)
end

if Rails.version < '4.1'
  ActiveRecord::Base.class_eval do
    mattr_accessor :dump_schema_after_migration, instance_writer: false
    self.dump_schema_after_migration = true
  end
end

module CanvasRails
  class Application < Rails::Application
    config.autoload_paths += [config.root.join('lib').to_s]
    $LOAD_PATH << config.root.to_s
    config.encoding = 'utf-8'
    require_dependency 'logging_filter'
    config.filter_parameters.concat LoggingFilter.filtered_parameters
    config.action_dispatch.rescue_responses['AuthenticationMethods::AccessTokenError'] = 401
    config.action_dispatch.rescue_responses['AuthenticationMethods::LoggedOutError'] = 401
    if CANVAS_RAILS3
      config.action_dispatch.rescue_responses['ActionController::ParameterMissing'] = 400
    else
      config.action_dispatch.default_headers['X-UA-Compatible'] = "IE=Edge,chrome=1"
      config.action_dispatch.default_headers.delete('X-Frame-Options')
    end

    config.app_generators do |c|
      c.test_framework :rspec
      c.integration_tool :rspec
      c.performance_tool :rspec
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # See Rails::Configuration for more options.

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
    config.time_zone = 'UTC'

    log_config = File.exist?(Rails.root+"config/logging.yml") && YAML.load_file(Rails.root+"config/logging.yml")[Rails.env]
    log_config = { 'logger' => 'rails', 'log_level' => 'debug' }.merge(log_config || {})
    opts = {}
    require 'canvas_logger'

    config.log_level = log_config['log_level']
    log_level = (CANVAS_RAILS3 ? ActiveSupport::BufferedLogger : ActiveSupport::Logger).const_get(config.log_level.to_s.upcase)
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
        log_path = config.paths['log'].first

        if ENV['RUNNING_AS_DAEMON'] == 'true'
          log_path = Rails.root+'log/delayed_job.log'
        end

        config.logger = CanvasLogger.new(log_path, log_level, opts)
    end

    # Activate observers that should always be running
    config.active_record.observers = [:cacher, :stream_item_cache, :live_events_observer ]

    config.active_record.whitelist_attributes = false

    config.autoload_paths += %W(#{Rails.root}/app/middleware
                            #{Rails.root}/app/observers
                            #{Rails.root}/app/presenters
                            #{Rails.root}/app/services
                            #{Rails.root}/app/serializers
                            #{Rails.root}/app/presenters)

    # prevent directory->module inference in these directories from wreaking
    # havoc on the app (e.g. stylesheets/base -> ::Base)
    config.eager_load_paths -= %W(#{Rails.root}/app/coffeescripts
                                  #{Rails.root}/app/stylesheets)

    # we don't know what middleware to make SessionsTimeout follow until after
    # we've loaded config/initializers/session_store.rb
    initializer("extend_middleware_stack", after: "load_config_initializers") do |app|
      app.config.middleware.insert_before(config.session_store, 'LoadAccount')
      app.config.middleware.insert_before(config.session_store, 'SessionsTimeout')
      app.config.middleware.swap('ActionDispatch::RequestId', "RequestContextGenerator")
      app.config.middleware.insert_before('ActionDispatch::ParamsParser', 'Canvas::RequestThrottle')
      app.config.middleware.insert_before('Rack::MethodOverride', 'PreventNonMultipartParse')
    end

    config.to_prepare do
      require_dependency 'canvas/plugins/default_plugins'
      ActiveSupport::JSON::Encoding.escape_html_entities_in_json = true
    end

    module PostgreSQLPreparedStatementsDefault
      def initialize(connection, logger, connection_parameters, config)
        unless config.key?(:prepared_statements)
          config = config.dup
          config[:prepared_statements] = false
        end
        super(connection, logger, connection_parameters, config)
      end
    end

    Autoextend.hook(:"ActiveRecord::ConnectionAdapters::PostgreSQLAdapter",
                    PostgreSQLPreparedStatementsDefault,
                    method: :prepend)

    if CANVAS_RAILS3
      module PostgreSQLConnectTimeoutParam
        def postgresql_connection(config) # :nodoc:
          config = config.symbolize_keys
          config[:user] ||= config.delete(:username) if config.key?(:username)

          if config.key?(:database)
            config[:dbname] = config[:database]
          else
            raise ArgumentError, "No database specified. Missing argument: database."
          end
          conn_params = config.slice(:host, :port, :dbname, :user, :password, :connect_timeout)

          # The postgres drivers don't allow the creation of an unconnected PGconn object,
          # so just pass a nil connection object for the time being.
          ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.new(nil, logger, [conn_params], config)
        end
      end

      Autoextend.hook(:"ActiveRecord::ConnectionAdapters::PostgreSQLAdapter") do
        ActiveRecord::Base.singleton_class.prepend(PostgreSQLConnectTimeoutParam)
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
      tag:yaml.org,2002:timestamp
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
    ActiveSupport::XmlMini.backend = 'Nokogiri'

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

    if defined?(Spring)
      Spring.after_fork do
        Canvas.reconnect_redis
      end
    end

    # don't wrap fields with errors with a <div class="fieldWithErrors" />,
    # since that could leak information (e.g. valid vs invalid username on
    # login page)
    config.action_view.field_error_proc = Proc.new { |html_tag, instance| html_tag }

    class ExceptionsApp
      def call(env)
        @app_controller ||= ActionDispatch::Routing::RouteSet::Dispatcher.new.controller(:controller => 'application')
        @app_controller.action('rescue_action_dispatch_exception').call(env)
      end
    end

    config.exceptions_app = ExceptionsApp.new

    config.before_initialize do
      config.action_controller.asset_host = Canvas::Cdn.method(:asset_host_for)
    end
  end
end

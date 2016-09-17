# Put this in config/application.rb
require File.expand_path('../boot', __FILE__)

require_relative '../lib/canvas_yaml'

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

if CANVAS_RAILS4_0
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
    config.action_dispatch.default_headers['X-UA-Compatible'] = "IE=Edge,chrome=1"
    config.action_dispatch.default_headers.delete('X-Frame-Options')

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
    log_level = ActiveSupport::Logger.const_get(config.log_level.to_s.upcase)
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
    config.active_record.observers = [:cacher, :stream_item_cache, :live_events_observer, :conditional_release_observer ]

    config.active_record.whitelist_attributes = false

    unless CANVAS_RAILS4_0
      config.active_record.raise_in_transactional_callbacks = true # may as well opt into the new behavior
    end
    config.active_support.encode_big_decimal_as_string = false

    config.autoload_paths += %W(#{Rails.root}/app/middleware
                            #{Rails.root}/app/observers
                            #{Rails.root}/app/presenters
                            #{Rails.root}/app/services
                            #{Rails.root}/app/serializers
                            #{Rails.root}/app/presenters)

    config.autoload_once_paths << Rails.root.join("app/middleware")

    # prevent directory->module inference in these directories from wreaking
    # havoc on the app (e.g. stylesheets/base -> ::Base)
    config.eager_load_paths -= %W(#{Rails.root}/app/coffeescripts
                                  #{Rails.root}/app/stylesheets)

    # we don't know what middleware to make SessionsTimeout follow until after
    # we've loaded config/initializers/session_store.rb
    initializer("extend_middleware_stack", after: "load_config_initializers") do |app|
      app.config.middleware.insert_before(config.session_store, 'LoadAccount')
      app.config.middleware.insert_before(config.session_store, 'SessionsTimeout')
      app.config.middleware.swap('ActionDispatch::RequestId', 'RequestContextGenerator')
      app.config.middleware.insert_after(config.session_store, 'RequestContextSession')
      app.config.middleware.insert_before('ActionDispatch::ParamsParser', 'RequestThrottle')
      app.config.middleware.insert_before('Rack::MethodOverride', 'PreventNonMultipartParse')
    end

    config.to_prepare do
      require_dependency 'canvas/plugins/default_plugins'
      ActiveSupport::JSON::Encoding.escape_html_entities_in_json = true
    end

    module PostgreSQLEarlyExtensions
      def initialize(connection, logger, connection_parameters, config)
        unless config.key?(:prepared_statements)
          config = config.dup
          config[:prepared_statements] = false
        end
        super(connection, logger, connection_parameters, config)
      end

      def connect
        hosts = Array(@connection_parameters[:host]).presence || [nil]
        hosts.each_with_index do |host, index|
          begin
            connection_parameters = @connection_parameters.dup
            connection_parameters[:host] = host
            @connection = PGconn.connect(connection_parameters)

            raise "Canvas requires PostgreSQL 9.3 or newer" unless postgresql_version >= 90300

            if CANVAS_RAILS4_0
              ActiveRecord::ConnectionAdapters::PostgreSQLColumn.money_precision = (postgresql_version >= 80300) ? 19 : 10
            else
              ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Money.precision = (postgresql_version >= 80300) ? 19 : 10
            end

            configure_connection

            break
          rescue ::PG::Error => error
            if !CANVAS_RAILS4_0 && error.message.include?("does not exist")
              raise ActiveRecord::NoDatabaseError.new(error.message, error)
            elsif index == hosts.length - 1
              raise
            end
            # else try next host
          end
        end
      end
    end

    Autoextend.hook(:"ActiveRecord::ConnectionAdapters::PostgreSQLAdapter",
                    PostgreSQLEarlyExtensions,
                    method: :prepend)

    SafeYAML.singleton_class.send(:attr_accessor, :safe_parsing)
    module SafeYAMLWithFlag
      def load(*args)
        previous, self.safe_parsing = safe_parsing, true
        super
      ensure
        self.safe_parsing = previous
      end
    end
    SafeYAML.singleton_class.prepend(SafeYAMLWithFlag)

    # safe_yaml can't whitelist specific instances of scalar values, so just override the loading
    # here, and do a weird check
    YAML.add_ruby_type("object:Class") do |_type, val|
      if SafeYAML.safe_parsing && !Canvas::Migration.valid_converter_classes.include?(val)
        raise "Cannot load class #{val} from YAML"
      end
      val.constantize
    end

    # TODO: Use this instead of the above block when we switch to Psych
    Psych.add_domain_type("ruby/object", "Class") do |_type, val|
      if SafeYAML.safe_parsing && !Canvas::Migration.valid_converter_classes.include?(val)
        raise "Cannot load class #{val} from YAML"
      end
      val.constantize
    end

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
        @app_controller ||= ActionDispatch::Routing::RouteSet::Dispatcher.new({}).controller(:controller => 'application')
        @app_controller.action('rescue_action_dispatch_exception').call(env)
      end
    end

    config.exceptions_app = ExceptionsApp.new

    config.before_initialize do
      config.action_controller.asset_host = Canvas::Cdn.method(:asset_host_for)
    end

    if config.action_dispatch.rack_cache != false
      config.action_dispatch.rack_cache[:ignore_headers] =
        %w[Set-Cookie X-Request-Context-Id X-Canvas-User-Id X-Canvas-Meta]
    end
  end
end

#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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

module CanvasRails
  class Application < Rails::Application
    $LOAD_PATH << config.root.to_s
    config.encoding = 'utf-8'
    require 'logging_filter'
    config.filter_parameters.concat LoggingFilter.filtered_parameters
    config.action_dispatch.rescue_responses['AuthenticationMethods::AccessTokenError'] = 401
    config.action_dispatch.rescue_responses['AuthenticationMethods::AccessTokenScopeError'] = 401
    config.action_dispatch.rescue_responses['AuthenticationMethods::LoggedOutError'] = 401
    config.action_dispatch.default_headers['X-UA-Compatible'] = "IE=Edge,chrome=1"
    config.action_dispatch.default_headers.delete('X-Frame-Options')
    config.action_controller.forgery_protection_origin_check = true
    ActiveSupport.to_time_preserves_timezone = true

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

    config.active_support.encode_big_decimal_as_string = false

    config.paths['lib'].eager_load!
    config.paths.add('app/middleware', eager_load: true, autoload_once: true)

    # prevent directory->module inference in these directories from wreaking
    # havoc on the app (e.g. stylesheets/base -> ::Base)
    config.eager_load_paths -= %W(#{Rails.root}/app/coffeescripts
                                  #{Rails.root}/app/stylesheets)

    # we don't know what middleware to make SessionsTimeout follow until after
    # we've loaded config/initializers/session_store.rb
    initializer("extend_middleware_stack", after: "load_config_initializers") do |app|
      app.config.middleware.insert_before(config.session_store, LoadAccount)
      app.config.middleware.swap(ActionDispatch::RequestId, RequestContextGenerator)
      app.config.middleware.insert_after(config.session_store, RequestContextSession)
      app.config.middleware.insert_before(Rack::Head, RequestThrottle)
      app.config.middleware.insert_before(Rack::MethodOverride, PreventNonMultipartParse)
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
            @connection = PG::Connection.connect(connection_parameters)

            raise "Canvas requires PostgreSQL 9.5 or newer" unless postgresql_version >= 90500

            configure_connection

            break
          rescue ::PG::Error => error
            if error.message.include?("does not exist")
              raise ActiveRecord::NoDatabaseError.new(error.message)
            elsif index == hosts.length - 1
              raise
            end
            # else try next host
          end
        end
      end
    end

    module TypeMapInitializerExtensions
      if CANVAS_RAILS5_1
        def query_conditions_for_initial_load(type_map)
          known_type_names = type_map.keys.map { |n| "'#{n}'" } + type_map.keys.map { |n| "'_#{n}'" }
          <<-SQL % [known_type_names.join(", "),]
            WHERE
              t.typname IN (%s)
          SQL
        end
      else
        def query_conditions_for_initial_load
          known_type_names = @store.keys.map { |n| "'#{n}'" } + @store.keys.map { |n| "'_#{n}'" }
          <<-SQL % [known_type_names.join(", "),]
            WHERE
              t.typname IN (%s)
          SQL
        end
      end
    end

    Autoextend.hook(:"ActiveRecord::ConnectionAdapters::PostgreSQLAdapter",
                    PostgreSQLEarlyExtensions,
                    method: :prepend)

    Autoextend.hook(:"ActiveRecord::ConnectionAdapters::PostgreSQL::OID::TypeMapInitializer",
                    TypeMapInitializerExtensions,
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

    Psych.add_domain_type("ruby/object", "Class") do |_type, val|
      if SafeYAML.safe_parsing && !Canvas::Migration.valid_converter_classes.include?(val)
        raise "Cannot load class #{val} from YAML"
      end
      val.constantize
    end

    module PatchThorWarning
      # active_model_serializers should be passing `type: :boolean` here:
      # https://github.com/rails-api/active_model_serializers/blob/v0.9.0.alpha1/lib/active_model/serializer/generators/serializer/scaffold_controller_generator.rb#L10
      # but we don't really care about the warning, it only affects using the rails
      # generator for a resource
      #
      # Easiest way to avoid the warning for now is to patch thor
      def validate_default_type!
        return if switch_name == "--serializer"
        super
      end
    end

    Autoextend.hook(:"Thor::Option", PatchThorWarning, method: :prepend)

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
          # if redis failed, we would have established a connection to the
          # database (trying to read the ignore_redis_failures setting), but
          # we're running in the main passenger thread, and Rails will get mad
          # at us if we try to use that connection in a different thread (the
          # worker thread that actually processes requests). So just always
          # close the connections again
          ActiveRecord::Base.clear_all_connections!
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
        req = ActionDispatch::Request.new(env)
        res = ApplicationController.make_response!(req)
        ApplicationController.dispatch('rescue_action_dispatch_exception', req, res)
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

    def validate_secret_key_config!
      # no validation; we don't use Rails' CookieStore session middleware, so we
      # don't care about secret_key_base
    end
  end
end

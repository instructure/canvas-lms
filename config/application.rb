# frozen_string_literal: true

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

require_relative "boot"

require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "sprockets/railtie" # Do not enable the Rails Asset Pipeline
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

debug_launch = lambda do
  if ENV["RUBY_DEBUG_OPEN"]
    require "debug/session"
    next unless defined?(DEBUGGER__)

    DEBUGGER__.open(nonstop: ENV["RUBY_DEBUG_NONSTOP"])
  elsif ENV["RUBY_DEBUG_START"]
    require "debug/start" # rubocop:disable Lint/Debugger
  end
end

Spring.after_fork(&debug_launch) if defined?(Spring)
debug_launch.call if !defined?(Passenger) && Rails.env.development?

module CanvasRails
  class Application < Rails::Application
    config.autoloader = :zeitwerk

    config.add_autoload_paths_to_load_path = false

    config.encoding = "utf-8"
    require "logging_filter"
    config.filter_parameters.concat LoggingFilter.filtered_parameters
    config.action_dispatch.rescue_responses["AuthenticationMethods::AccessTokenError"] = 401
    config.action_dispatch.rescue_responses["AuthenticationMethods::AccessTokenScopeError"] = 401
    config.action_dispatch.rescue_responses["AuthenticationMethods::LoggedOutError"] = 401
    config.action_dispatch.rescue_responses["CanvasHttp::CircuitBreakerError"] = 502
    config.action_dispatch.default_headers.delete("X-Frame-Options")
    config.action_dispatch.default_headers["Referrer-Policy"] = "no-referrer-when-downgrade"
    config.action_controller.forgery_protection_origin_check = true
    ActiveSupport.to_time_preserves_timezone = true
    # Ensure switchman gets the new version before the main initialize_cache initializer runs
    config.active_support.cache_format_version = ActiveSupport.cache_format_version = 7.0

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
    config.time_zone = "UTC"

    log_config = Rails.root.join("config/logging.yml").file? && Rails.application.config_for(:logging).with_indifferent_access
    log_config = { "logger" => "rails", "log_level" => "debug" }.merge(log_config || {})

    config.log_level = log_config["log_level"]
    log_level = Logger.const_get(config.log_level.to_s.upcase)

    case log_config["logger"]
    when "syslog"
      require "syslog/logger"
      log_config["app_ident"] ||= "canvas-lms"
      log_config["daemon_ident"] ||= "canvas-lms-daemon"
      facilities = 0
      (log_config["facilities"] || []).each do |facility|
        facilities |= Syslog.const_get :"LOG_#{facility.to_s.upcase}"
      end
      ident = (ENV["RUNNING_AS_DAEMON"] == "true") ? log_config["daemon_ident"] : log_config["app_ident"]

      config.logger = Syslog::Logger.new(ident, facilities)

      syslog_options = (log_config["include_pid"] == true) ? Syslog::LOG_PID : 0
      if (Syslog.instance.options & Syslog::LOG_PID) != syslog_options
        config.logger.syslog = Syslog.reopen(Syslog.instance.ident,
                                             (Syslog.instance.options & ~Syslog::LOG_PID) | syslog_options,
                                             Syslog.instance.facility)
      end
    else
      require "canvas_logger"
      log_path = config.paths["log"].first

      if ENV["RUNNING_AS_DAEMON"] == "true"
        log_path = Rails.root.join("log/delayed_job.log")
      end

      FileUtils.mkdir_p(File.dirname(log_path))
      config.logger = CanvasLogger.new(log_path, log_level)
    end
    config.logger.level = log_level
    unless log_config["log_context"] == false
      class ContextFormatter < Logger::Formatter
        def initialize(parent_formatter)
          super()

          @parent_formatter = parent_formatter
        end

        def call(severity, time, progname, msg)
          msg = @parent_formatter.call(severity, time, progname, msg)
          context = Thread.current[:context] || {}
          "[#{context[:session_id] || "-"} #{context[:request_id] || "-"}] #{msg}"
        end
      end

      config.logger.formatter = ContextFormatter.new(config.logger.formatter)
    end

    # Activate observers that should always be running
    config.active_record.observers = %i[cacher stream_item_cache live_events_observer]

    config.active_support.encode_big_decimal_as_string = false
    config.active_support.remove_deprecated_time_with_zone_name = true

    config.paths["lib"].eager_load!
    config.paths.add("app/middleware", eager_load: true, autoload_once: true)
    # The main autoloader should ignore it so the `once` autoloader can happily load it
    Rails.autoloaders.main.ignore("#{__dir__}/../lib/base")
    config.paths.add("lib/base", eager_load: true, autoload_once: true)
    $LOAD_PATH << "#{__dir__}/../lib/base"

    # This needs to be set for things in the `once` autoloader really early
    Rails.autoloaders.each do |autoloader|
      autoloader.inflector.inflect(
        "csv_with_i18n" => "CSVWithI18n"
      )
    end

    # prevent directory->module inference in these directories from wreaking
    # havoc on the app (e.g. stylesheets/base -> ::Base)
    config.eager_load_paths -= [Rails.root.join("app/coffeescripts"),
                                Rails.root.join("app/stylesheets"),
                                Rails.root.join("ui")]

    config.middleware.use Rack::Chunked
    config.middleware.use Rack::Deflater, if: lambda { |*|
      ::DynamicSettings.find(tree: :private)["enable_rack_deflation", failsafe: true]
    }
    config.middleware.use Rack::Brotli, if: lambda { |*|
      ::DynamicSettings.find(tree: :private)["enable_rack_brotli", failsafe: true]
    }

    config.i18n.load_path << Rails.root.join("config/locales/locales.yml")
    config.i18n.load_path << Rails.root.join("config/locales/community.csv")

    config.to_prepare do
      Canvas::Plugins::DefaultPlugins.apply_all
      ActiveSupport::JSON::Encoding.escape_html_entities_in_json = true
    end

    module PostgreSQLEarlyExtensions
      module ConnectionHandling
        def postgresql_connection(config)
          conn_params = config.symbolize_keys

          hosts = Array(conn_params[:host]).presence || [nil]
          hosts.each_with_index do |host, index|
            conn_params[:host] = host

            begin
              return super(conn_params)
            rescue ::ActiveRecord::ActiveRecordError, ::PG::Error => e
              # If exception occurs using parameters from a predefined pg service, retry without
              if conn_params.key?(:service)
                CanvasErrors.capture(e, { tags: { pg_service: conn_params[:service] } }, :warn)
                Rails.logger.warn("Error connecting to database using pg service `#{conn_params[:service]}`; retrying without... (error: #{e.message})")
                conn_params.delete(:service)
                conn_params[:sslmode] = "disable"
                retry
              else
                raise
              end
            end
            # we _shouldn't_ be catching a NoDatabaseError, but that's what Rails raises
            # for an error where the database name is in the message (i.e. a hostname lookup failure)
          rescue ::ActiveRecord::NoDatabaseError, ::ActiveRecord::ConnectionNotEstablished
            raise if index == hosts.length - 1
            # else try next host
          end
        end
      end

      if Rails.version < "7.1"
        def initialize(connection, logger, connection_parameters, config)
          unless config.key?(:prepared_statements)
            config = config.dup
            config[:prepared_statements] = false
          end
          super(connection, logger, connection_parameters, config)
        end
      else
        def initialize(config)
          unless config.key?(:prepared_statements)
            config = config.dup
            config[:prepared_statements] = false
          end
          super(config)
        end
      end

      def connect
        hosts = Array(@connection_parameters[:host]).presence || [nil]
        hosts.each_with_index do |host, index|
          connection_parameters = @connection_parameters.dup
          connection_parameters[:host] = host

          begin
            if Rails.version < "7.1"
              @connection = PG::Connection.connect(connection_parameters)
            else
              @raw_connection = PG::Connection.connect(connection_parameters)
            end
          rescue ::ActiveRecord::ActiveRecordError, ::PG::Error => e
            # If exception occurs using parameters from a predefined pg service, retry without
            if connection_parameters.key?(:service)
              CanvasErrors.capture(e, { tags: { pg_service: connection_parameters[:service] } }, :warn)
              Rails.logger.warn("Error connecting to database using pg service `#{connection_parameters[:service]}`; retrying without... (error: #{e.message})")
              connection_parameters.delete(:service)
              connection_parameters[:sslmode] = "disable"
              retry
            else
              raise
            end
          end

          configure_connection

          raise "Canvas requires PostgreSQL 12 or newer" unless postgresql_version >= 12_00_00 # rubocop:disable Style/NumericLiterals

          break
        rescue ::PG::Error => e
          if e.message.include?("does not exist")
            raise ActiveRecord::NoDatabaseError, e.message
          elsif index == hosts.length - 1
            raise
          end
          # else try next host
        end
      end
    end

    module TypeMapInitializerExtensions
      def query_conditions_for_initial_load
        known_type_names = @store.keys.map { |n| "'#{n}'" } + @store.keys.map { |n| "'_#{n}'" }
        <<~SQL.squish % [known_type_names.join(", "),]
          WHERE
            t.typname IN (%s)
        SQL
      end
    end

    Autoextend.hook(:"ActiveRecord::Base",
                    PostgreSQLEarlyExtensions::ConnectionHandling,
                    singleton: true)
    Autoextend.hook(:"ActiveRecord::ConnectionAdapters::PostgreSQLAdapter",
                    PostgreSQLEarlyExtensions,
                    method: :prepend)
    Autoextend.hook(:"ActiveRecord::ConnectionAdapters::PostgreSQL::OID::TypeMapInitializer",
                    TypeMapInitializerExtensions,
                    method: :prepend)

    module RailsCacheShim
      def delete(key, options = nil)
        if options&.[](:unprefixed_key)
          super
        else
          # Any is eager, so we must map first or we won't run on all keys
          SUPPORTED_RAILS_VERSIONS.map do |version|
            super(key, (options || {}).merge(explicit_version: version.delete(".")))
          end.any?
        end
      end

      private

      def namespace_key(key, options)
        # Purge all rails versions at once if deleting based on a pattern
        if caller_locations(1, 1).first.base_label == "delete_matched"
          return "rails??:#{super}"
        end

        if options&.[](:unprefixed_key)
          super
        elsif options&.[](:explicit_version)
          "rails#{options[:explicit_version]}:#{super}"
        else
          "rails#{Rails::VERSION::MAJOR}#{Rails::VERSION::MINOR}:#{super}"
        end
      end
    end

    Autoextend.hook(:"ActiveSupport::Cache::Store",
                    RailsCacheShim,
                    method: :prepend)

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

    # tell Rails to use the native XML parser instead of REXML
    ActiveSupport::XmlMini.backend = "Nokogiri"

    class NotImplemented < StandardError; end

    if defined?(PhusionPassenger)
      PhusionPassenger.on_event(:after_installing_signal_handlers) do
        Canvas::Reloader.trap_signal
      end
    else
      config.to_prepare do
        Canvas::Reloader.trap_signal
      end
    end

    # Ensure that the automatic redis reconnection on fork works
    # This is the default in redis-rb, but for some reason rails overrides it
    # See e.g. https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22704
    ActiveSupport::Cache::RedisCacheStore::DEFAULT_REDIS_OPTIONS[:reconnect_attempts] = 1

    # don't wrap fields with errors with a <div class="fieldWithErrors" />,
    # since that could leak information (e.g. valid vs invalid username on
    # login page)
    config.action_view.field_error_proc = proc { |html_tag, _instance| html_tag }

    class ExceptionsApp
      def call(env)
        req = ActionDispatch::Request.new(env)
        res = ApplicationController.make_response!(req)
        ApplicationController.dispatch("rescue_action_dispatch_exception", req, res)
      end
    end

    config.exceptions_app = ExceptionsApp.new

    config.before_initialize do
      config.action_controller.asset_host = lambda do |source, *_|
        ::Canvas::Cdn.asset_host_for(source)
      end
    end

    if config.action_dispatch.rack_cache != false
      config.action_dispatch.rack_cache[:ignore_headers] =
        %w[Set-Cookie X-Request-Context-Id X-Canvas-User-Id X-Canvas-Meta]
    end

    def validate_secret_key_base(_)
      # no validation; we don't use Rails' CookieStore session middleware, so we
      # don't care about secret_key_base
    end

    class DummyKeyGenerator
      def self.generate_key(*); end
    end

    def key_generator(...)
      DummyKeyGenerator
    end

    # # This also depends on secret_key_base and is not a feature we use or currently intend to support
    unless Rails.version < "7.1"
      initializer "canvas.ignore_generated_token_verifier", before: "active_record.generated_token_verifier" do
        config.after_initialize do
          ActiveSupport.on_load(:active_record) do
            self.generated_token_verifier = "UNUSED"
          end
        end
      end
    end

    initializer "canvas.init_dynamic_settings", before: "canvas.extend_shard" do
      settings = ConfigFile.load("consul")
      if settings.present?
        # this is not just for speed in non-consul installations^
        # We also do things like building javascript assets with the base
        # container that only has as many ruby assets as strictly necessary,
        # and these resources actually aren't even on disk in those cases.
        # do not remove this conditional until the asset build no longer
        # needs the rails app for anything.

        # Do it early with the wrong cache for things super early in boot
        reloader = DynamicSettingsInitializer.bootstrap!
        # Do it at the end when the autoloader is set up correctly
        config.to_prepare do
          reloader.call
        end
      end
    end

    initializer "canvas.extend_shard", before: "active_record.initialize_database" do
      # have to do this before the default shard loads
      Switchman::Shard.serialize :settings, type: Hash
      Switchman.cache = -> { MultiCache.cache }
    end

    # Newer rails has this in rails proper
    attr_writer :credentials

    initializer "canvas.init_credentials", before: "active_record.initialize_database" do
      self.credentials = Canvas::Credentials.new(credentials)
      # Ensure we load credentials at initailization time to avoid overloading vault
      credentials.config
    end

    # we don't know what middleware to make SessionsTimeout follow until after
    # we've loaded config/initializers/session_store.rb
    initializer("extend_middleware_stack", after: :load_config_initializers) do |app|
      app.config.middleware.insert_before(config.session_store, LoadAccount)
      app.config.middleware.swap(ActionDispatch::RequestId, RequestContext::Generator)
      app.config.middleware.insert_after(config.session_store, RequestContext::Session)
      app.config.middleware.insert_before(Rack::Head, RequestThrottle)
      app.config.middleware.insert_before(Rack::MethodOverride, PreventNonMultipartParse)
      app.config.middleware.insert_before(Sentry::Rails::CaptureExceptions, SentryTraceScrubber)
    end

    initializer("set_allowed_request_id_setters", after: :finisher_hook) do |app|
      # apparently there is no initialization hook that comes late enough for
      # routes to already be loaded, so we have to load them explicitly
      app.reload_routes!
      RequestContext::Generator.allow_unsigned_request_context_for(
        app.routes.url_helpers.api_graphql_subgraph_path
      )
    end
  end
end

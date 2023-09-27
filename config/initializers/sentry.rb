# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

# This initializer is for the Sentry exception tracking system.
#
# Sentry's config file would be "config/sentry.yml". If that config doesn't exist,
# nothing happens.  If it *does*, we register a callback with Canvas::Errors
# so that every time an exception is reported, we can fire off a sentry
# call to track it and aggregate it for us.

Rails.configuration.to_prepare do
  settings = Rails.env.test? ? {} : SentryExtensions::Settings.settings

  unless Sentry.initialized?
    Sentry.init do |config|
      config.dsn = settings[:dsn]
      config.environment = Canvas.environment
      config.release = "canvas-lms@#{Canvas.semver_revision}"
      config.sample_rate = SentryExtensions::Settings.get("sentry_backend_errors_sample_rate", "1.0").to_f

      config.traces_sampler = lambda do |sampling_context|
        unless sampling_context[:parent_sampled].nil?
          # If there is a parent transaction, abide by its sampling decision
          next sampling_context[:parent_sampled]
        end

        SentryExtensions::Settings.get("sentry_backend_traces_sample_rate", "0.0").to_f
      end

      # Override the Sentry-provided ActiveRecord subscriber with our own (to normalize SQL queries)
      config.rails.tracing_subscribers.delete(Sentry::Rails::Tracing::ActiveRecordSubscriber)
      config.rails.tracing_subscribers.add(SentryExtensions::Tracing::ActiveRecordSubscriber)

      # sentry_logger would be nice here (it records log messages), but it currently includes raw SQL logs
      config.breadcrumbs_logger = [:http_logger] if Canvas::Plugin.value_to_boolean(SentryExtensions::Settings.get("sentry_backend_breadcrumbs_enabled", "false"))

      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      config.before_send = lambda do |event, _|
        filter.filter(event.to_hash)
      end

      # this array should only contain exceptions that are intentionally
      # thrown to drive client facing behavior.  A good example
      # are login/auth exceptions.  Exceptions that are simply noisy/inconvenient
      # should probably be caught and solved...
      config.excluded_exceptions += %w[
        AuthenticationMethods::AccessTokenError
        AuthenticationMethods::AccessTokenScopeError
        AuthenticationMethods::LoggedOutError
        ActionController::InvalidAuthenticityToken
        Delayed::Backend::JobExpired
        Folio::InvalidPage
        Turnitin::Errors::SubmissionNotScoredError
        Rack::QueryParser::InvalidParameterError
        PG::UnableToSend
      ]

      # Add some dirs to the the default (db, engines, gems, script)-this is combined with the base dir so vendored gems won't be included
      config.app_dirs_pattern = /(app|bin|config|db|engines|gems|lib|script)/
    end
  end

  Sentry.set_tags(settings.fetch(:tags, {}))

  Canvas::Reloader.on_reload do
    Sentry.configuration&.sample_rate = SentryExtensions::Settings.get("sentry_backend_errors_sample_rate", "1.0").to_f
  end

  SentryExtensions::Settings.get("ignorable_errors", "").split(",").each do |error|
    SentryProxy.register_ignorable_error(error)
  end

  # These errors can be caused by LTI tools.
  SentryProxy.register_ignorable_error("Grade pass back failure")
  SentryProxy.register_ignorable_error("Grade pass back unsupported")

  CanvasErrors.register!(:sentry_notification) do |exception, data, level|
    setting = SentryExtensions::Settings.get("sentry_error_logging_enabled", "true", skip_cache: data[:skip_setting_cache])
    SentryProxy.capture(exception, data, level) if setting == "true"
  end
end

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

settings = {}

unless Rails.env.test? || SentryExtensions::Settings.disabled?
  settings = SentryExtensions::Settings.settings
end

Sentry.init do |config|
  config.traces_sampler = lambda do |_|
    SentryExtensions::Settings.get("sentry_backend_traces_sample_rate", "0.0").to_f
  end
  config.rails.tracing_subscribers = [
    Sentry::Rails::Tracing::ActionControllerSubscriber,
    Sentry::Rails::Tracing::ActionViewSubscriber,
    Sentry::Rails::Tracing::ActiveStorageSubscriber,
    SentryExtensions::Tracing::ActiveRecordSubscriber # overridden from the Sentry-provided one
  ]

  config.dsn = settings[:dsn]
  config.environment = Canvas.environment
  config.release = Canvas.revision

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
    Folio::InvalidPage
    Turnitin::Errors::SubmissionNotScoredError
    Rack::QueryParser::InvalidParameterError
    PG::UnableToSend
  ]
end

Sentry.set_tags(settings.fetch(:tags, {}))

Rails.configuration.to_prepare do
  SentryExtensions::Settings.get("ignorable_errors", "").split(",").each do |error|
    SentryProxy.register_ignorable_error(error)
  end

  # This error can be caused by LTI tools.
  SentryProxy.register_ignorable_error("Grade pass back failure")

  CanvasErrors.register!(:sentry_notification) do |exception, data, level|
    setting = SentryExtensions::Settings.get("sentry_error_logging_enabled", "true")
    SentryProxy.capture(exception, data, level) if setting == "true"
  end
end

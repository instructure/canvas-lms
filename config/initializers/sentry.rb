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
# "Sentry" is the ruby library that is the client to sentry, and it's
# config file would be "config/sentry.yml". If that config doesn't exist,
# nothing happens.  If it *does*, we register a callback with Canvas::Errors
# so that every time an exception is reported, we can fire off a sentry
# call to track it and aggregate it for us.
settings = ConfigFile.load("sentry")

if settings.present?

  Sentry.init do |config|
    config.dsn = settings[:dsn]
    config.breadcrumbs_logger = [:sentry_logger, :http_logger]
    config.capture_exception_frame_locals = true
    config.transport.ssl_verification = false
    config.release = Canvas.revision
    config.enabled_environments = %w[ production ]
    config.excluded_exceptions += %w{
      AuthenticationMethods::AccessTokenError
      AuthenticationMethods::LoggedOutError
      ActionController::InvalidAuthenticityToken
      Folio::InvalidPage
      Turnitin::Errors::SubmissionNotScoredError
      ActiveRecord::ConcurrentMigrationError
    }
    config.before_send = lambda do |event, hint|
      if event.exception&.instance_variable_get(:@values)&.first&.type == "ActiveRecord::RecordInvalid" && hint[:exception].message == "Validation failed: Email is invalid"
        nil
      else
        event
      end
    end

    config.traces_sampler = lambda do |sampling_context|
      rack_env = sampling_context[:env]
      return 1 if rack_env && rack_env.try(:[], 'QUERY_STRING')&.include?('sentry')
      transaction_context = sampling_context[:transaction_context]
      return 0.001 if transaction_context[:name].match?(/grade_passback$/)
      0.0
    end
  end

  Sentry.set_tags(settings.fetch(:tags, {}).merge(
    'canvas_revision' => Canvas.revision,
    'canvas_domain' => ENV['CANVAS_DOMAIN'],
    'node_id' => ENV['NODE']
  ))

  Rails.configuration.to_prepare do
    Canvas::Errors.register!(:sentry_notification) do |exception, data|
      setting = Setting.get("sentry_error_logging_enabled", 'true')
      SentryProxy.capture(exception, data) if setting == 'true'
    end
  end
end

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
# "Raven" is the ruby library that is the client to sentry, and it's
# config file would be "config/raven.yml". If that config doesn't exist,
# nothing happens.  If it *does*, we register a callback with Canvas::Errors
# so that every time an exception is reported, we can fire off a sentry
# call to track it and aggregate it for us.
settings = ConfigFile.load("raven")

if settings.present?
  require "raven/base"
  Raven.configure do |config|
    config.logger = Rails.logger
    config.silence_ready = true
    config.dsn = settings[:dsn]
    config.tags = settings.fetch(:tags, {}).merge('canvas_revision' => Canvas.revision)
    config.release = Canvas.revision
    config.sanitize_fields += Rails.application.config.filter_parameters.map(&:to_s)
    config.sanitize_credit_cards = false
    config.excluded_exceptions += %w{
      AuthenticationMethods::AccessTokenError
      AuthenticationMethods::LoggedOutError
      ActionController::InvalidAuthenticityToken
      Folio::InvalidPage
      Turnitin::Errors::SubmissionNotScoredError
      ConditionalRelease::ServiceError
    }
  end

  Rails.configuration.to_prepare do
    Setting.get('ignorable_errors', '').split(',').each do |error|
      SentryProxy.register_ignorable_error(error)
    end

    # This error can be caused by LTI tools.
    SentryProxy.register_ignorable_error("Grade pass back failure")

    Canvas::Errors.register!(:sentry_notification) do |exception, data|
      setting = Setting.get("sentry_error_logging_enabled", 'true')
      SentryProxy.capture(exception, data) if setting == 'true'
    end
  end
end

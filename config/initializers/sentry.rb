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

  # Inline PII scrubbing for FERPA compliance purposes.
  # Mirrors PlatformSdk::Sentry::PiiScrubber::DEFAULT_PII_FIELDS but
  # implemented inline because strongmind-platform-sdk requires
  # Rails >= 7.1 / Ruby >= 2.6 (canvas-lms is Rails 5 / Ruby 2.5).
  PII_FIELDS = [
    :email, /\Aname\z/i, :first_name, :last_name, :student_name,
    :username, :phone, :phone_number, :address, :street, :city,
    :zip, :postal_code, :ssn, :social_security, :date_of_birth,
    :dob, :birthday, :ip_address, /\Aip\z/i, :remote_ip,
    :password, :password_confirmation, :token, :secret, :api_key,
    :authorization
  ].freeze
  PII_FILTERED = '[FILTERED]'.freeze
  PII_EMAIL_REGEX = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/

  pii_filter = ActionDispatch::Http::ParameterFilter.new(PII_FIELDS)

  scrub_hash = lambda do |hash|
    hash.is_a?(Hash) ? pii_filter.filter(hash) : {}
  end

  scrub_user = lambda do |user_hash|
    id = user_hash[:id] || user_hash['id']
    scrubbed = scrub_hash.call(user_hash)
    scrubbed[:id] = id if user_hash.key?(:id)
    scrubbed['id'] = id if user_hash.key?('id')
    scrubbed
  end

  scrub_request = lambda do |request|
    if request.data.is_a?(Hash)
      request.data = scrub_hash.call(request.data)
    end
    if request.headers.is_a?(Hash)
      request.headers = scrub_hash.call(request.headers)
    end
    request.query_string = PII_FILTERED if request.query_string
    request.cookies = PII_FILTERED if request.cookies
  end

  scrub_event = lambda do |event|
    if event.user.is_a?(Hash)
      event.user = scrub_user.call(event.user)
    end
    if event.extra.is_a?(Hash)
      event.extra = scrub_hash.call(event.extra)
    end
    if event.contexts.is_a?(Hash)
      event.contexts = scrub_hash.call(event.contexts)
    end
    scrub_request.call(event.request) if event.request
    event
  end

  sentry_ignored_urls = [
    %r{/up$}i, %r{/health_check$}i, %r{/favicon\.ico$}i,
    %r{/robots\.txt$}i, %r{/nuclei.svg$}i, %r{/wp-admin}i,
    %r{/cgi-bin}i, %r{/jmx-console}i, %r{/manager/html}i,
    %r{/phpmyadmin}i, /.+\.php$/i, /.+\.ini$/i, /.+\.env$/i,
    /.+\.txt$/i, /.+\.jsp$/i, /.+\.do$/i, /.+\.srf$/i,
    /.+\.bak$/i, /.+\.cfml?$/i, /.+\.cgi$/i
  ].freeze

  Sentry.init do |config|
    config.dsn = settings[:dsn]
    config.breadcrumbs_logger = [:sentry_logger, :http_logger]
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
      Rack::Timeout::RequestTimeoutException
    }

    config.before_send = lambda do |event, hint|
      if event.exception&.instance_variable_get(:@values)&.
           first&.type == "ActiveRecord::RecordInvalid" &&
         hint[:exception].message ==
           "Validation failed: Email is invalid"
        nil
      else
        scrub_event.call(event)
      end
    end

    config.before_breadcrumb = lambda do |breadcrumb, _hint|
      if breadcrumb.data.is_a?(Hash)
        breadcrumb.data = scrub_hash.call(breadcrumb.data)
      end
      if breadcrumb.message
        breadcrumb.message = breadcrumb.message.gsub(
          PII_EMAIL_REGEX, PII_FILTERED
        )
      end
      breadcrumb
    end

    config.traces_sampler = lambda do |sampling_context|
      unless sampling_context[:parent_sampled].nil?
        next sampling_context[:parent_sampled]
      end
      rack_env = sampling_context[:env]
      if rack_env &&
         rack_env.try(:[], 'QUERY_STRING')&.include?('sentry')
        return 1
      end
      if rack_env &&
         rack_env.try(:[], 'PATH_INFO') =~ /grade_passback$/
        return 0.01
      end

      0.0001
    end

    config.before_send_transaction = lambda do |event, _hint|
      if event.transaction_info[:source] == :url &&
         sentry_ignored_urls.any? { |u| event.transaction.match?(u) }
        return nil
      end
      scrub_event.call(event)
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

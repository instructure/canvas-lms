# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
#

#
# Client to access Microsoft's login API, necessary to use the graph API (see
# GraphService)
#
module MicrosoftSync
  module LoginService
    class TenantDoesNotExist < MicrosoftSync::Errors::GracefulCancelError
      def self.public_message
        I18n.t "Microsoft tenant does not exist."
      end
    end

    BASE_URL = "https://login.microsoftonline.com"
    TOKEN_SUBPATH = "oauth2/v2.0/token"
    REDIRECT_URI = "https://www.instructure.com/"

    # Tokens are normally 3599 or 3600 seconds. Assume it will be and adjust
    # the expiry if it isn't.
    CACHE_DEFAULT_EXPIRY = 3599.seconds
    # Give us a little breathing room from when they say the token will expire.
    CACHE_EXPIRY_BUFFER = 8.seconds
    CACHE_RACE_CONDITION_TTL = 5.seconds

    STATSD_NAME = "microsoft_sync.login_service"

    class << self
      def login_url(tenant)
        "#{BASE_URL}/#{tenant}/#{TOKEN_SUBPATH}"
      end

      # Returns JSON returned from endpoint, including 'access_token' and 'expires_in'
      def new_token(tenant)
        raise ArgumentError, "MicrosoftSync not configured" unless client_id && client_secret

        headers = { "Content-Type" => "application/x-www-form-urlencoded" }
        body = {
          scope: "https://graph.microsoft.com/.default",
          grant_type: "client_credentials",
          client_id:,
          client_secret:,
        }

        response = Canvas.timeout_protection("microsoft_sync_login", raise_on_timeout: true) do
          HTTParty.post(login_url(tenant), body:, headers:)
        end

        unless (200..299).cover?(response.code)
          # Probably the key itself is bad. As of 3/2021, it seems like if the tenant
          # hasn't granted permission, we get a token but then a 401 from the Graph API
          raise MicrosoftSync::Errors::HTTPInvalidStatus.for(
            service: "login", tenant:, response:
          )
        end

        response.parsed_response
      rescue Errors::HTTPBadRequest
        if response.body =~ /Tenant .* not found/ || response.body.include?("is neither a valid DNS name")
          raise TenantDoesNotExist
        end

        raise
      ensure
        statsd_tags = { status_code: response&.code&.to_s || "error" }
        InstStatsd::Statsd.increment(STATSD_NAME, tags: statsd_tags)
      end

      # Returns a string token. Cached per-tenant for the time given in the login response.
      def token(tenant)
        cache_key = ["microsoft_sync_login", tenant]

        new_value = expiry = nil
        result = Rails.cache.fetch(
          cache_key,
          expires_in: CACHE_DEFAULT_EXPIRY - CACHE_EXPIRY_BUFFER - CACHE_RACE_CONDITION_TTL,
          race_condition_ttl: CACHE_RACE_CONDITION_TTL
        ) do
          response = new_token(tenant)
          expiry = response["expires_in"]&.seconds
          new_value = response["access_token"]
        end

        # If we just got a new token, update the expiry with what Microsoft
        # gives us, if it is different than what we expect. We cannot pass it
        # into fetch() above because we don't know it at that point.
        if expiry && expiry != CACHE_DEFAULT_EXPIRY
          Rails.cache.write(
            cache_key,
            new_value,
            expires_in: expiry - CACHE_EXPIRY_BUFFER - CACHE_RACE_CONDITION_TTL,
            race_condition_ttl: CACHE_RACE_CONDITION_TTL
          )
        end

        result
      end

      def client_id
        settings[:client_id]
      end

      private

      def settings
        Rails.application.credentials&.microsoft_sync&.with_indifferent_access || {}
      end

      def client_secret
        settings[:client_secret]
      end
    end
  end
end

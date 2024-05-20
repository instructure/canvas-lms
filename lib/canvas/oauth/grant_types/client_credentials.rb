# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../client_credentials_provider"

module Canvas::OAuth
  module GrantTypes
    class ClientCredentials < BaseType
      def initialize(opts, host, root_account, protocol = nil) # rubocop:disable Lint/MissingSuper
        @provider = client_credential_provider_for(opts, host, root_account, protocol:)
        @secret = secret_for(@provider, opts)
      end

      def supported_type?
        true
      end

      private

      def client_credential_provider_for(opts, host, root_account, protocol: nil)
        if opts[:client_assertion_type] == "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
          raw_jwt = opts[:client_assertion]
          return Canvas::OAuth::AsymmetricClientCredentialsProvider.new(
            raw_jwt,
            host,
            scopes: scopes_from_opts(opts),
            protocol:
          )
        end

        client_id = opts[:client_id]
        key = key_for(client_id)

        if key&.site_admin_service_auth?
          return Canvas::OAuth::ServiceUserClientCredentialsProvider.new(
            client_id,
            host,
            scopes: scopes_from_opts(opts),
            protocol:,
            key:,
            root_account:
          )
        end

        Canvas::OAuth::SymmetricClientCredentialsProvider.new(client_id, host, scopes: scopes_from_opts(opts), protocol:)
      end

      def secret_for(provider, opts)
        provider.try(:secret) || opts[:client_secret]
      end

      def key_for(client_id)
        DeveloperKey.find_cached(client_id)
      rescue ::ActiveRecord::RecordNotFound
        nil
      end

      def validate_type
        unless @provider.assertion_method_permitted?
          raise Canvas::OAuth::InvalidRequestError, "assertion method not supported for this grant_type"
        end

        raise Canvas::OAuth::InvalidRequestError, @provider.error_message unless @provider.valid?
        raise Canvas::OAuth::InvalidScopeError, @provider.missing_scopes unless @provider.valid_scopes?
      end

      def generate_token
        @provider.generate_token
      end

      def basic_auth?(opts)
        opts[:client_assertion_type] != "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
      end

      def scopes_from_opts(opts)
        (opts[:scope] || opts[:scopes] || "").split
      end
    end
  end
end

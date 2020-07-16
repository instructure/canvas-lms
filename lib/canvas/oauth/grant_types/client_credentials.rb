
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

module Canvas::Oauth
  module GrantTypes
    class ClientCredentials < BaseType
      def initialize(opts, host, protocol = nil)
        if opts[:client_assertion_type] == 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
          raw_jwt = opts.fetch(:client_assertion)
          @provider = Canvas::Oauth::AsymmetricClientCredentialsProvider.new(raw_jwt, host, scopes_from_opts(opts), protocol)
          @secret = @provider.key&.api_key
        else
          client_id = opts.fetch(:client_id)
          @provider = Canvas::Oauth::SymmetricClientCredentialsProvider.new(client_id, host, scopes_from_opts(opts), protocol)
          if @provider.key&.client_credentials_audience != "external"
            raise Canvas::Oauth::InvalidRequestError, 'assertion method not supported for this grant_type'
          end
          @secret = opts.fetch(:client_secret)
        end
      end

      def supported_type?
        true
      end

      private

      def validate_type
        raise Canvas::Oauth::InvalidRequestError, @provider.error_message unless @provider.valid?
        raise Canvas::Oauth::InvalidScopeError, @provider.missing_scopes unless @provider.valid_scopes?
      end

      def generate_token
        @provider.generate_token
      end

      def basic_auth?(opts)
        opts[:client_assertion_type] != 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
      end

      def scopes_from_opts(opts)
        (opts[:scope] || opts[:scopes] || '').split(' ')
      end
    end
  end
end

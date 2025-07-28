# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "oauth2"

class OAuthValidationError < RuntimeError
end

class RetriableOAuthValidationError < OAuthValidationError
end

class AuthenticationProvider::OAuth2 < AuthenticationProvider::Delegated
  class << self
    def sensitive_params
      [*super, :client_secret].freeze
    end
  end

  # rename DB fields to something that makes sense for OAuth2
  alias_method :client_secret=, :auth_password=
  alias_method :client_secret, :auth_decrypted_password
  alias_attribute :client_id, :entity_id
  alias_attribute :authorize_url, :log_in_url
  alias_attribute :token_url, :auth_base
  alias_attribute :scope, :requested_authn_context

  def client
    @client ||= ::OAuth2::Client.new(client_id, client_secret, client_options)
  end

  def generate_authorize_url(redirect_uri, state, nonce:, **authorize_options)
    client.auth_code.authorize_url({ redirect_uri:, state: }
                                   .merge(self.authorize_options)
                                   .merge(authorize_options))
  end

  def get_token(code, redirect_uri, _params)
    client.auth_code.get_token(code, { redirect_uri: }.merge(token_options))
  end

  def provider_attributes(_token)
    {}
  end

  # Invoked prior to logging a user in with the found pseudonym.
  #
  # The AuthenticationProvider can apply an custom validations and raise
  # one of the following errors if validation fails:
  #   - RetriableOAuthValidationError (the user should be redirected to the auth provider's
  #     validation_error_retry_url for retrying
  #   - OAuthValidationError (The login should fail without a redirect to the auth provider's
  #      validation_error_retry_url)
  def validate_found_pseudonym!(pseudonym:, session:, token:, target_auth_provider:)
    nil
  end

  # Used when #validate_found_pseudonym! raises a RetriableOAuthValidationError.
  #
  # The authentication provider should return a URL to redirect the user to for retrying
  def validation_error_retry_url(_error, controller:, target_auth_provider:)
    nil
  end

  protected

  def client_options
    {
      authorize_url:,
      token_url:
    }
  end

  def authorize_options
    {}
  end

  def token_options
    {}
  end
end

#
# Copyright (C) 2015 Instructure, Inc.
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

require 'oauth2'

class AccountAuthorizationConfig::Oauth2 < AccountAuthorizationConfig::Delegated

  SENSITIVE_PARAMS = [ :client_secret ].freeze

  # rename DB fields to something that makes sense for OAuth2
  alias_method :client_secret=, :auth_password=
  alias_method :client_secret, :auth_decrypted_password
  { client_id: :entity_id,
    authorize_url: :log_in_url,
    token_url: :auth_base,
    scope: :requested_authn_context }.each do |(new_name, old_name)|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{new_name}=(val)
        self.#{old_name} = val
      end

      def #{new_name}
        #{old_name}
      end
    RUBY
  end

  def client
    @client ||= OAuth2::Client.new(client_id, client_secret, client_options)
  end

  def generate_authorize_url(redirect_uri, state)
    client.auth_code.authorize_url({ redirect_uri: redirect_uri, state: state }.merge(authorize_options))
  end

  def get_token(code, redirect_uri)
    client.auth_code.get_token(code, { redirect_uri: redirect_uri }.merge(token_options))
  end

  protected

  def client_options
    {
      authorize_url: authorize_url,
      token_url: token_url
    }
  end

  def authorize_options
    {}
  end

  def token_options
    {}
  end
end

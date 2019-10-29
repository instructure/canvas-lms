#
# Copyright (C) 2019 - present Instructure, Inc.
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

Pact.provider_states_for PactConfig::Consumers::ALL do

  provider_state 'an account with an LTI developer key' do
    set_up do
      account = Pact::Canvas.base_state.account
      jwk = {
          "kty" => 'RSA',
          "e" => 'test',
          "n" => 'test',
          "kid" => 'test',
          "alg" => 'RS256',
          "use" => 'test',
          "iss" => 'test',
          "aud" => 'http://example.org/login/oauth2/token',
          "sub" => 'test',
          "exp" => (Time.zone.now + 10.minutes).to_i,
          "iat" => Time.zone.now.to_i,
          "jti" => 'test',
        }
      developer_key = account.developer_keys.create!(
        public_jwk: jwk,
        public_jwk_url: 'example.org',
        scopes: [
          "https://canvas.instructure.com/lti/public_jwk/scope/update",
          "https://canvas.instructure.com/lti/data_services/scope/create",
          "https://canvas.instructure.com/lti/data_services/scope/show",
          "https://canvas.instructure.com/lti/data_services/scope/update",
          "https://canvas.instructure.com/lti/data_services/scope/list",
          "https://canvas.instructure.com/lti/data_services/scope/destroy",
          "https://canvas.instructure.com/lti/data_services/scope/list_event_types",
        ]
      )
      allow_any_instance_of(Canvas::Oauth::Provider).
        to receive(:key).and_return(developer_key)

      allow_any_instance_of(Canvas::Oauth::ClientCredentialsProvider).
        to receive(:get_jwk_from_url).and_return(jwk)
    end
  end

  provider_state 'a course with live events' do
    set_up do
      Canvas::Security.class_eval do
        @old_decode_jwt = self.method(:decode_jwt)

        def self.decode_jwt(body, keys = [])
          @old_decode_jwt.call(body, keys, ignore_expiration: true)
        end
      end
    end

    tear_down do
      Canvas::Security.class_eval do
        define_singleton_method(:decode_jwt, @old_decode_jwt)
        remove_instance_variable(:@old_decode_jwt)
      end
    end
  end
end

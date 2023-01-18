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

shared_context "advantage access token context" do
  let_once(:root_account) do
    Account.default
  end
  let_once(:developer_key) do
    dk = DeveloperKey.create!(account: root_account)
    dk.developer_key_account_bindings.first.update! workflow_state: "on"
    dk
  end
  let(:access_token_scopes) do
    %w[
      https://purl.imsglobal.org/spec/lti-ags/scope/lineitem
      https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly
      https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly
      https://canvas.instructure.com/lti/public_jwk/scope/update
      https://canvas.instructure.com/lti/data_services/scope/create
      https://canvas.instructure.com/lti/data_services/scope/show
      https://canvas.instructure.com/lti/data_services/scope/update
      https://canvas.instructure.com/lti/data_services/scope/list
      https://canvas.instructure.com/lti/data_services/scope/destroy
      https://canvas.instructure.com/lti/data_services/scope/list_event_types
      https://canvas.instructure.com/lti/account_lookup/scope/show
      https://canvas.instructure.com/lti/feature_flags/scope/show
      https://canvas.instructure.com/lti/account_external_tools/scope/create
      https://canvas.instructure.com/lti/account_external_tools/scope/update
      https://canvas.instructure.com/lti/account_external_tools/scope/list
      https://canvas.instructure.com/lti/account_external_tools/scope/show
      https://canvas.instructure.com/lti/account_external_tools/scope/destroy
    ].join(" ")
  end
  let(:access_token_signing_key) { Canvas::Security.encryption_key }
  let(:test_request_host) { "test.host" }
  let(:access_token_aud) { "http://#{test_request_host}/login/oauth2/token" }
  let(:access_token_jwt_hash) do
    timestamp = Time.zone.now.to_i
    {
      iss: "https://canvas.instructure.com",
      sub: developer_key.global_id,
      aud: access_token_aud,
      iat: timestamp,
      exp: (timestamp + 1.hour.to_i),
      nbf: (timestamp - 30),
      jti: SecureRandom.uuid,
      scopes: access_token_scopes
    }
  end
  let(:access_token_jwt) do
    return nil if access_token_jwt_hash.blank?

    JSON::JWT.new(access_token_jwt_hash).sign(access_token_signing_key, :HS256).to_s
  end
end

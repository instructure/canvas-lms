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

RSpec.shared_context "deep_linking_spec_helper" do
  let(:account) { account_model }
  let(:iss) { developer_key.global_id }
  let(:aud) { Canvas::Security.config["lti_iss"] }
  let(:response_message_type) { "LtiDeepLinkingResponse" }
  let(:lti_version) { "1.3.0" }
  let(:deployment_id) { "deployment id" }
  let(:content_items) { [] }
  let(:msg) { "some message" }
  let(:errormsg) { "error_message" }
  let(:alg) { :RS256 }
  let(:iat) { Time.zone.now.to_i }
  let(:exp) { 5.minutes.from_now.to_i }
  let(:jti) { SecureRandom.uuid }
  let(:log) { "log" }
  let(:errorlog) { "error log" }
  let(:deep_linking_jwt) do
    body = {
      "iss" => iss,
      "aud" => aud,
      "iat" => iat,
      "exp" => exp,
      "jti" => jti,
      "nonce" => SecureRandom.uuid,
      "https://purl.imsglobal.org/spec/lti/claim/message_type" => response_message_type,
      "https://purl.imsglobal.org/spec/lti/claim/version" => lti_version,
      "https://purl.imsglobal.org/spec/lti/claim/deployment_id" => deployment_id,
      "https://purl.imsglobal.org/spec/lti-dl/claim/content_items" => content_items,
      "https://purl.imsglobal.org/spec/lti-dl/claim/msg" => msg,
      "https://purl.imsglobal.org/spec/lti-dl/claim/errormsg" => errormsg,
      "https://purl.imsglobal.org/spec/lti-dl/claim/log" => log,
      "https://purl.imsglobal.org/spec/lti-dl/claim/errorlog" => errorlog
    }
    JSON::JWT.new(body).sign(private_jwk, alg).to_s
  end
  let(:developer_key) do
    key = DeveloperKey.new(account:)
    key.generate_rsa_keypair!
    key.save!
    key.developer_key_account_bindings.first.update!(
      workflow_state: "on"
    )
    key
  end
  let(:public_jwk) { JSON::JWK.new(developer_key.public_jwk) }
  let(:private_jwk) { JSON::JWK.new(developer_key.private_jwk) }
end

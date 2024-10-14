# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

RSpec.describe Canvas::OAuth::GrantTypes::AuthorizationCodeWithPKCE do # rubocop:disable RSpec/SpecFilePathFormat
  let(:key) { DeveloperKey.create! }
  let(:client_id) { key.global_id }
  let(:secret) { key.api_key }
  let(:opts) { { code: "test_code", code_verifier: "test_code_verifier" } }
  let(:provider) { instance_double(Canvas::OAuth::Provider) }
  let(:token) { instance_double(Canvas::OAuth::Token) }
  let(:authorization_code_with_pkce) { described_class.new(client_id, secret, opts) }

  before do
    allow(Canvas::OAuth::Provider).to receive(:new).with(client_id).and_return(provider)

    allow(provider).to receive(:is_authorized_by?).with(secret).and_return(true)
    allow(provider).to receive_messages(has_valid_key?: true, token_for: token)

    allow(token).to receive_messages(is_for_valid_code?: true, key:, client_id:)
  end

  describe "#allow_public_client?" do
    it "returns true" do
      expect(authorization_code_with_pkce.allow_public_client?).to be true
    end
  end

  describe "#validate_type" do
    context "when PKCE code verifier is valid" do
      it "calls super method" do
        allow(Canvas::OAuth::PKCE).to receive(:valid_code_verifier?).with(code: opts[:code], code_verifier: opts[:code_verifier]).and_return(true)
        expect { authorization_code_with_pkce.send(:validate_type) }.not_to raise_error
      end
    end

    context "when PKCE code verifier is invalid" do
      it "raises Canvas::OAuth::RequestError with :invalid_grant" do
        allow(Canvas::OAuth::PKCE).to receive(:valid_code_verifier?).with(code: opts[:code], code_verifier: opts[:code_verifier]).and_return(false)
        expect { authorization_code_with_pkce.send(:validate_type) }.to raise_error(Canvas::OAuth::RequestError)
      end
    end
  end
end

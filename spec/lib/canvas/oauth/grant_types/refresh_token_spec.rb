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

RSpec.describe Canvas::OAuth::GrantTypes::RefreshToken do # rubocop:disable RSpec/SpecFilePathFormat
  let(:key) { DeveloperKey.create! }
  let(:client_id) { key.global_id }
  let(:secret) { key.api_key }
  let(:opts) { { refresh_token: "test_refresh_token" } }
  let(:provider) { instance_double(Canvas::OAuth::Provider) }
  let(:token) { instance_double(Canvas::OAuth::Token) }
  let(:access_token) { key.access_tokens.create! }
  let(:refresh_token_instance) { described_class.new(client_id, secret, opts) }

  before do
    allow(Canvas::OAuth::Provider).to receive(:new).with(client_id).and_return(provider)
    allow(provider).to receive(:is_authorized_by?).with(secret).and_return(true)
    allow(provider).to receive(:token_for_refresh_token).with(opts[:refresh_token]).and_return(token)
    allow(provider).to receive_messages(has_valid_key?: true, key:)

    allow(token).to receive_messages(access_token:, key:)
  end

  describe "#supported_type?" do
    it "returns true" do
      expect(refresh_token_instance.supported_type?).to be true
    end
  end

  describe "#allow_public_client?" do
    it "returns true" do
      expect(refresh_token_instance.allow_public_client?).to be true
    end
  end

  describe "#validate_type" do
    context "when refresh_token is not supplied" do
      let(:opts) { {} }

      it "raises Canvas::OAuth::RequestError with :refresh_token_not_supplied" do
        expect { refresh_token_instance.send(:validate_type) }.to raise_error(Canvas::OAuth::RequestError)
      end
    end

    context "when refresh_token is invalid" do
      before do
        allow(provider).to receive(:token_for_refresh_token).with(opts[:refresh_token]).and_return(nil)
      end

      it "raises Canvas::OAuth::RequestError with :invalid_refresh_token" do
        expect { refresh_token_instance.send(:validate_type) }.to raise_error(Canvas::OAuth::RequestError)
      end
    end

    context "when client_id does not match" do
      before do
        allow(access_token).to receive(:developer_key_id).and_return(nil)
      end

      it "raises Canvas::OAuth::RequestError with :incorrect_client" do
        expect { refresh_token_instance.send(:validate_type) }.to raise_error(Canvas::OAuth::RequestError)
      end
    end
  end

  describe "#generate_token" do
    context "when the client is public" do
      let(:key) { DeveloperKey.create!(client_type: DeveloperKey::PUBLIC_CLIENT_TYPE) }

      before do
        allow(Account.site_admin).to receive(:feature_enabled?).with(:pkce).and_return(true)
      end

      it "regenerates access token and sets permanent expiration" do
        expect(access_token).to receive(:regenerate_access_token)
        expect(access_token).to receive(:set_permanent_expiration)
        expect(access_token).to receive(:generate_refresh_token).with(overwrite: true)
        expect(access_token).to receive(:save)

        refresh_token_instance.token
      end
    end

    context "when provider.key.public_client? is false" do
      before do
        allow(Account.site_admin).to receive(:feature_enabled?).with(:pkce).and_return(true)
      end

      it "regenerates access token without setting permanent expiration" do
        expect(access_token).to receive(:regenerate_access_token)
        expect(access_token).not_to receive(:set_permanent_expiration)
        expect(access_token).not_to receive(:generate_refresh_token)
        expect(access_token).not_to receive(:save)

        refresh_token_instance.token
      end
    end
  end
end

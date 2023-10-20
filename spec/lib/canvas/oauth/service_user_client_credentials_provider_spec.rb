# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe Canvas::OAuth::ServiceUserClientCredentialsProvider do
  include_context "InstAccess setup"

  let(:service_user) { user_model }
  let(:root_account) { account_model }
  let(:dev_key) { DeveloperKey.create!(service_user:) }
  let(:provider) { described_class.new dev_key&.id, "example.com", root_account: }

  before do
    allow(Rails.application.routes).to receive(:default_url_options).and_return({ host: "example.com" })
  end

  describe "#valid?" do
    subject { provider.valid? }

    context "when the developer key is nil" do
      let(:dev_key) { nil }

      it { is_expected.to be false }

      it "includes the correct error message" do
        subject

        expect(provider.error_message).to eq("Unknown client_id")
      end
    end

    context "when the developer key is not usable" do
      before { dev_key.destroy! }

      it { is_expected.to be false }

      it "includes the correct error message" do
        subject

        expect(provider.error_message).to eq("Unknown client_id")
      end
    end

    context "when the service user is blank" do
      let(:service_user) { nil }

      it { is_expected.to be false }

      it "includes the correct error message" do
        subject

        expect(provider.error_message).to eq("No active service")
      end
    end

    context "whent he service user is deleted" do
      before { service_user.destroy! }

      it { is_expected.to be false }

      it "includes the correct error message" do
        subject

        expect(provider.error_message).to eq("No active service")
      end
    end
  end

  describe "#generate_token" do
    subject { provider.generate_token.as_json }

    it "generates an access token for the service user" do
      token = AuthenticationMethods::InstAccessToken.parse(subject["access_token"])

      expect(token.user_uuid).to eq service_user.uuid
    end

    it "generates a token that expires in an hour" do
      token = AuthenticationMethods::InstAccessToken.parse(subject["access_token"])

      expect(Time.at(token.jwt_payload[:exp])).to be_within(
        30.seconds
      ).of(1.hour.from_now)
    end
  end
end

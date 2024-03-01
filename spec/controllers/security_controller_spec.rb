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

RSpec.describe SecurityController, type: :request do
  # This uses the lti keyset, but it doesn't really matter which one
  let(:url) { Rails.application.routes.url_helpers.lti_jwks_path }
  let(:json) { response.parsed_body }

  let(:past_key) { CanvasSecurity::KeyStorage.new_key }
  let(:present_key) { CanvasSecurity::KeyStorage.new_key }
  let(:future_key) { CanvasSecurity::KeyStorage.new_key }

  let(:fallback_proxy) do
    DynamicSettings::FallbackProxy.new({
                                         CanvasSecurity::KeyStorage::PAST => past_key,
                                         CanvasSecurity::KeyStorage::PRESENT => present_key,
                                         CanvasSecurity::KeyStorage::FUTURE => future_key
                                       })
  end

  around do |example|
    Timecop.freeze(&example)
  end

  before do
    allow(DynamicSettings).to receive(:kv_proxy).and_return(fallback_proxy)
  end

  it "returns ok status" do
    get url
    expect(response).to have_http_status :ok
  end

  it "returns a jwk set" do
    get url
    expect(json["keys"]).not_to be_empty
  end

  it "sets the Cache-control header" do
    get url
    expect(response.headers["Cache-Control"]).to include "max-age=864000"
  end

  it "returns well-formed public key jwks" do
    get url
    expected_keys = %w[kid kty alg e n use]
    json["keys"].each do |key|
      expect(key.keys - expected_keys).to be_empty
    end
  end

  context "with ?rotation_check=1" do
    let(:past_key) { Timecop.travel(1.month.ago) { CanvasSecurity::KeyStorage.new_key } }
    let(:future_key) { Timecop.travel(1.month.from_now) { CanvasSecurity::KeyStorage.new_key } }

    it "returns whether each key is from the current month" do
      # This is memoized, so make sure we get the new one we make in this test
      expect(Lti::KeyStorage).to receive(:consul_proxy).at_least(:once).and_return(fallback_proxy)

      day = Time.zone.now.utc.to_date.day
      get url, params: { rotation_check: "1" }
      expect(json).to eq([
                           "today is day #{day} and key 0 is not from this month",
                           "today is day #{day} and key 1 is from this month",
                           "today is day #{day} and key 2 is not from this month"
                         ])
    end
  end

  describe "openid_configuration" do
    before do
      allow(Lti::Oidc).to receive(:auth_domain).and_return("canvas.instructure.com")
    end

    it "rejects timed-out tokens" do
      jwt = Canvas::Security.create_jwt({
                                          user_id: 1,
                                          root_account_uuid: Account.default.uuid
                                        },
                                        5.minutes.ago)

      get "/api/lti/security/openid-configuration", headers: { "Authorization" => "Bearer #{jwt}" }
      expect(response).to have_http_status :unauthorized
    end

    it "contains the correct information" do
      jwt = Canvas::Security.create_jwt({
                                          user_id: 1,
                                          root_account_global_id: Account.default.global_id
                                        },
                                        5.minutes.from_now)

      messages = Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE.keys.map(&:to_s).map do |message_type|
        {
          "type" => message_type,
          "placements" => Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE[message_type].reject { |p| p == :resource_selection }.map(&:to_s)
        }
      end

      get "/api/lti/security/openid-configuration?registration_token=#{jwt}"
      expect(response).to have_http_status :ok
      parsed_body = response.parsed_body
      expect(parsed_body["issuer"]).to eq "https://canvas.instructure.com"
      expect(parsed_body["authorization_endpoint"]).to eq "http://canvas.instructure.com/api/lti/authorize_redirect"
      expect(parsed_body["registration_endpoint"]).to eq "http://localhost/api/lti/registrations"
      expect(parsed_body["jwks_uri"]).to eq "http://canvas.instructure.com/api/lti/security/jwks"
      expect(parsed_body["token_endpoint"]).to eq "http://canvas.instructure.com/login/oauth2/token"
      lti_platform_configuration = parsed_body["https://purl.imsglobal.org/spec/lti-platform-configuration"]
      expect(lti_platform_configuration["product_family_code"]).to eq "canvas"
      expect(lti_platform_configuration["https://canvas.instructure.com/lti/account_name"]).to eq "Default Account"
      expect(lti_platform_configuration["messages_supported"]).to eq messages
    end
  end

  context "sharding" do
    specs_require_sharding

    before do
      allow(Lti::Oidc).to receive(:auth_domain).and_return("canvas.instructure.com")
    end

    describe "openid_configuration" do
      it "works cross-shard" do
        account_name = "Shard 2 Account"

        account = nil

        @shard2.activate do
          account = Account.create!(name: account_name, lti_guid: "shard2")
        end

        jwt = Canvas::Security.create_jwt({
                                            user_id: 1,
                                            root_account_global_id: account.global_id
                                          },
                                          5.minutes.from_now)

        get "/api/lti/security/openid-configuration?registration_token=#{jwt}"
        expect(response).to have_http_status :ok
        parsed_body = response.parsed_body
        expect(parsed_body["issuer"]).to eq "https://canvas.instructure.com"
        expect(parsed_body["authorization_endpoint"]).to eq "http://canvas.instructure.com/api/lti/authorize_redirect"
        expect(parsed_body["registration_endpoint"]).to eq "http://localhost/api/lti/registrations"
        lti_platform_configuration = parsed_body["https://purl.imsglobal.org/spec/lti-platform-configuration"]
        expect(lti_platform_configuration["product_family_code"]).to eq "canvas"
        expect(lti_platform_configuration["https://canvas.instructure.com/lti/account_name"]).to eq "Shard 2 Account"
        expect(lti_platform_configuration["https://canvas.instructure.com/lti/account_lti_guid"]).to eq "shard2"
      end
    end
  end
end

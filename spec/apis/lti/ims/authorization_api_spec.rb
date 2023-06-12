# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../../api_spec_helper"

module Lti
  module IMS
    describe AuthorizationController, type: :request do
      let(:account) { Account.create! }

      let(:developer_key) { DeveloperKey.create!(redirect_uri: "http://example.com/redirect") }

      let(:product_family) do
        ProductFamily.create(
          vendor_code: "123",
          product_code: "abc",
          vendor_name: "acme",
          root_account: account,
          developer_key:
        )
      end
      let(:tool_proxy) do
        ToolProxy.create!(
          context: account,
          guid: SecureRandom.uuid,
          shared_secret: "abc",
          product_family:,
          product_version: "1",
          workflow_state: "active",
          raw_data: { "enabled_capability" => ["Security.splitSecret"] },
          lti_version: "1"
        )
      end

      let(:raw_jwt) do
        raw_jwt = JSON::JWT.new(
          {
            sub: tool_proxy.guid,
            aud: polymorphic_url([account, :lti_oauth2_authorize]),
            exp: 1.minute.from_now,
            iat: Time.zone.now.to_i,
            jti: SecureRandom.uuid
          }
        )
        raw_jwt
      end

      let(:auth_endpoint) { polymorphic_url([account, :lti_oauth2_authorize]) }
      let(:jwt_string) do
        raw_jwt.sign(tool_proxy.shared_secret, :HS256).to_s
      end
      let(:params) do
        {
          grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
          assertion: jwt_string
        }
      end

      describe "POST 'authorize'" do
        it "responds with 200" do
          post(auth_endpoint, params:)
          expect(response).to have_http_status :ok
        end

        it "includes an expiration" do
          Setting.set("lti.oauth2.access_token.expiration", 1.hour.to_s)
          post(auth_endpoint, params:)
          expect(JSON.parse(response.body)["expires_in"]).to eq 1.hour.to_s
        end

        it "has a token_type of bearer" do
          post(auth_endpoint, params:)
          expect(JSON.parse(response.body)["token_type"]).to eq "bearer"
        end

        it "returns an access_token" do
          post(auth_endpoint, params:)
          access_token = Lti::OAuth2::AccessToken.create_jwt(aud: @request.host, sub: tool_proxy.guid)
          expect { access_token.validate! }.not_to raise_error
        end

        it "allows the use of the 'OAuth.splitSecret'" do
          tool_proxy.raw_data["enabled_capability"].delete("Security.splitSecret")
          tool_proxy.raw_data["enabled_capability"] << "OAuth.splitSecret"
          tool_proxy.save!
          post(auth_endpoint, params:)
          expect(response).to have_http_status :ok
        end

        it "renders a 400 if the JWT format is invalid" do
          params[:assertion] = "12ad3.4fgs56"
          post(auth_endpoint, params:)
          expect(response).to have_http_status :bad_request
        end

        it "renders a the correct json if the grant_type is invalid" do
          params[:assertion] = "12ad3.4fgs56"
          post(auth_endpoint, params:)
          expect(response.body).to eq({ error: "invalid_grant" }.to_json)
        end

        it "adds the file_host and the request host to the aud" do
          post(auth_endpoint, params:)
          file_host, _ = HostUrl.file_host_with_shard(@domain_root_account || Account.default, request.host_with_port)
          jwt = JSON::JWT.decode(JSON.parse(response.body)["access_token"], :skip_verification)
          expect(jwt["aud"]).to match_array [request.host, file_host]
        end

        context "when the account has a vanity domain" do
          subject do
            post(auth_endpoint, params:)
            JSON::JWT.decode(JSON.parse(response.body)["access_token"], :skip_verification)
          end

          let(:vanity_domain) { "canvas.school.com" }

          before do
            allow(HostUrl).to receive(:context_hosts).and_return([vanity_domain])
          end

          it "includes both domains in the aud" do
            expect(subject["aud"]).to match_array [
              "www.example.com",
              "localhost",
              "canvas.school.com"
            ]
          end
        end

        context "error reports" do
          it "creates an error report with error as the message" do
            params[:assertion] = "12ad3.4fgs56"
            post(auth_endpoint, params:)
            expect(ErrorReport.last.message).to eq "Invalid JWT Format. JWT should include 3 or 5 segments."
          end

          it "sets the error report category" do
            params[:assertion] = "12ad3.4fgs56"
            post(auth_endpoint, params:)
            expect(ErrorReport.last.category).to eq "JSON::JWT::InvalidFormat"
          end
        end

        context "reg_key" do
          let(:reg_key) { SecureRandom.uuid }

          let(:reg_password) { SecureRandom.uuid }

          let(:registration_url) { "http://example.com/register" }

          let(:raw_jwt) do
            RegistrationRequestService.cache_registration(account, reg_key, reg_password, registration_url)
            raw_jwt = JSON::JWT.new(
              {
                sub: reg_key,
                aud: polymorphic_url([account, :lti_oauth2_authorize]),
                exp: 1.minute.from_now,
                iat: Time.zone.now.to_i,
                jti: SecureRandom.uuid,
              }
            )
            raw_jwt
          end

          let(:jwt_string) do
            raw_jwt.sign(reg_password, :HS256).to_s
          end

          let(:params) do
            {
              grant_type: "authorization_code",
              assertion: jwt_string,
            }
          end

          it "accepts a valid reg_key" do
            enable_cache do
              post(auth_endpoint, params:)
              expect(response).to have_http_status :ok
            end
          end
        end

        context "developer credentials" do
          let(:raw_jwt) do
            raw_jwt = JSON::JWT.new(
              {
                sub: developer_key.global_id,
                aud: polymorphic_url([account, :lti_oauth2_authorize]),
                exp: 1.minute.from_now,
                iat: Time.zone.now.to_i,
                jti: SecureRandom.uuid,
              }
            )
            raw_jwt
          end

          let(:jwt_string) do
            raw_jwt.sign(developer_key.api_key, :HS256).to_s
          end

          let(:params) do
            {
              grant_type: "authorization_code",
              assertion: jwt_string,
              code: "reg_key"
            }
          end

          it "rejects the request if a valid reg_key isn't provided and grant_type is auth code" do
            post auth_endpoint, params: params.delete(:code)
            expect(response).to have_http_status :bad_request
          end

          it "accepts a developer key with a reg key" do
            post(auth_endpoint, params:)
            expect(response).to have_http_status :ok
          end
        end
      end
    end
  end
end

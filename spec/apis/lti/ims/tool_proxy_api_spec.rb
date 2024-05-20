# frozen_string_literal: true

#
# Copyright (C) 2014 Instructure, Inc.
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
require_relative "../lti2_api_spec_helper"
require_relative "../../api_spec_helper"

module Lti
  module IMS
    describe ToolProxyController, type: :request do
      include_context "lti2_api_spec_helper"

      let(:account) { Account.new }
      let(:product_family) do
        ProductFamily.create(vendor_code: "123", product_code: "abc", vendor_name: "acme", root_account: account)
      end
      let(:tool_proxy) do
        ToolProxy.create!(
          context: account,
          guid: SecureRandom.uuid,
          shared_secret: "abc",
          product_family:,
          product_version: "1",
          workflow_state: "disabled",
          raw_data: { "proxy" => "value" },
          lti_version: "1"
        )
      end

      let(:oauth1_header) do
        {
          "HTTP_AUTHORIZATION" => "OAuth
                oauth_consumer_key=\"#{tool_proxy.guid}\",
                oauth_signature_method=\"HMAC-SHA1\",
                oauth_signature=\"not_a_sig\",
                oauth_timestamp=\"137131200\",
                oauth_nonce=\"4572616e48616d6d65724c61686176\",
                oauth_version=\"1.0\" ".gsub(/\s+/, " ")
        }
      end

      describe "Get #show" do
        before do
          allow(OAuth::Signature).to receive(:build).and_return(double(verify: true))
          allow(OAuth::Helper).to receive(:parse_header).and_return({ "oauth_consumer_key" => "key" })
        end

        it "the tool proxy raw data" do
          get "/api/lti/tool_proxy/#{tool_proxy.guid}", params: { tool_proxy_guid: tool_proxy.guid }
          expect(JSON.parse(body)).to eq tool_proxy.raw_data
        end

        it "has the correct content-type" do
          get "/api/lti/tool_proxy/#{tool_proxy.guid}", params: { tool_proxy_guid: tool_proxy.guid }
          expect(response.headers["Content-Type"]).to include "application/vnd.ims.lti.v2.toolproxy+json"
        end
      end

      describe "POST #create" do
        before do
          mock_oauth_sig = double("oauth_signature")
          allow(mock_oauth_sig).to receive(:verify).and_return(true)
          allow(OAuth::Signature).to receive(:build).and_return(mock_oauth_sig)
          allow(OAuth::Helper).to receive(:parse_header).and_return({ "oauth_consumer_key" => "key" })
          allow(Lti::RegistrationRequestService).to receive(:retrieve_registration_password).and_return({
                                                                                                          reg_password: "password",
                                                                                                          registration_url: "http://example.com/register"
                                                                                                        })
        end

        it "returns a tool_proxy id object" do
          course_with_teacher_logged_in(active_all: true)
          tool_proxy_fixture = Rails.root.join("spec/fixtures/lti/tool_proxy.json").read
          json = JSON.parse(tool_proxy_fixture)
          json[:format] = "json"
          json[:account_id] = @course.account.id
          headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }.merge(oauth1_header)
          response = post("/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: tool_proxy_fixture, headers:)
          expect(response).to eq 201
          expect(JSON.parse(body).keys).to match_array ["@context", "@type", "@id", "tool_proxy_guid"]
        end

        it "has the correct content-type" do
          course_with_teacher_logged_in(active_all: true)
          tool_proxy_fixture = Rails.root.join("spec/fixtures/lti/tool_proxy.json").read
          headers = { "CONTENT_TYPE" => "application/vnd.ims.lti.v2.toolproxy+json",
                      "ACCEPT" => "application/vnd.ims.lti.v2.toolproxy.id+json" }.merge(oauth1_header)
          post("/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: tool_proxy_fixture, headers:)
          expect(response.headers["Content-Type"]).to include "application/vnd.ims.lti.v2.toolproxy.id+json"
        end

        it "returns an error message" do
          course_with_teacher_logged_in(active_all: true)
          tool_proxy_fixture = Rails.root.join("spec/fixtures/lti/tool_proxy.json").read
          tp = ::IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
          tp.tool_profile.resource_handlers.first.messages.first.enabled_capability = ["extra_capability"]
          headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }.merge(oauth1_header)
          response = post("/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: tp.to_json, headers:)
          expect(response).to eq 400
          expect(JSON.parse(body)).to eq({ "invalid_capabilities" => ["extra_capability"], "error" => "Invalid Capabilities" })
        end

        it "accepts split secret" do
          course_with_teacher_logged_in(active_all: true)
          # tool_proxy_fixture = Rails.root.join("spec/fixtures/lti/tool_proxy.json").read
          tool_proxy_fixture = JSON.parse(Rails.root.join("spec/fixtures/lti/tool_proxy.json").read)
          tool_proxy_fixture[:enabled_capability] = ["OAuth.splitSecret"]
          tool_proxy_fixture["security_contract"].delete("shared_secret")
          tool_proxy_fixture["security_contract"]["tp_half_shared_secret"] = SecureRandom.hex(128)
          headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }.merge(oauth1_header)
          response = post("/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: tool_proxy_fixture.to_json, headers:)
          expect(response).to eq 201
          expect(JSON.parse(body).keys).to match_array ["@context", "@type", "@id", "tool_proxy_guid", "tc_half_shared_secret"]
        end

        context "custom tool consumer profile" do
          let(:account) { Account.create! }
          let(:dev_key) do
            dev_key = DeveloperKey.create(api_key: "test-api-key", vendor_code:)
            dev_key
          end
          let!(:tcp) do
            dev_key.create_tool_consumer_profile!(
              services: Lti::ToolConsumerProfile::RESTRICTED_SERVICES,
              capabilities: Lti::ToolConsumerProfile::RESTRICTED_CAPABILITIES,
              uuid: SecureRandom.uuid,
              developer_key: dev_key
            )
          end
          let(:tcp_url) { polymorphic_url([account, :tool_consumer_profile], tool_consumer_profile_id: tcp.uuid) }
          let(:access_token) do
            aud = host rescue (@request || request).host
            Lti::OAuth2::AccessToken.create_jwt(aud:, sub: developer_key.global_id, reg_key: "reg_key")
          end
          let(:request_headers) { { Authorization: "Bearer #{access_token}" } }

          before { allow(DeveloperKey).to receive(:find_cached) { dev_key } }

          it "supports using a specified custom TCP" do
            course_with_teacher_logged_in(active_all: true)
            tool_proxy_fixture = Rails.root.join("spec/fixtures/lti/tool_proxy.json").read
            tp = ::IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
            tp.tool_profile.product_instance.product_info.product_family.vendor.code = vendor_code
            message = tp.tool_profile.resource_handlers.first.messages.first
            tp.tool_consumer_profile = tcp_url
            message.enabled_capability = *Lti::ToolConsumerProfile::RESTRICTED_CAPABILITIES
            headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }
            headers.merge!(request_headers)
            response = post("/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: tp.to_json, headers:)
            expect(response).to eq 201
          end
        end
      end

      describe "POST #create with JWT access token" do
        let(:access_token) do
          aud = host rescue (@request || request).host
          developer_key.update(vendor_code:)
          Lti::OAuth2::AccessToken.create_jwt(aud:, sub: developer_key.global_id, reg_key: "reg_key")
        end
        let(:request_headers) { { "Authorization" => "Bearer #{access_token}", "Content-Type" => "application/json" } }

        it "accepts valid JWT access tokens" do
          course_with_teacher_logged_in(active_all: true)
          allow(Lti::RegistrationRequestService).to receive(:retrieve_registration_password)
            .with(@course.account, "reg_key").and_return({
                                                           reg_password: "password",
                                                           registration_url: "http://example.com/register"
                                                         })
          tool_proxy_fixture = Rails.root.join("spec/fixtures/lti/tool_proxy.json").read
          tp = ::IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
          tp.tool_profile.product_instance.product_info.product_family.vendor.code = vendor_code
          response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: tp.to_json, headers: request_headers
          expect(response).to eq 201
        end

        it "returns a 401 if the reg_key is not valid" do
          course_with_teacher_logged_in(active_all: true)
          tool_proxy_fixture = Rails.root.join("spec/fixtures/lti/tool_proxy.json").read
          json = JSON.parse(tool_proxy_fixture)
          json[:format] = "json"
          json[:account_id] = @course.account.id
          response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: tool_proxy_fixture, headers: dev_key_request_headers
          expect(response).to eq 401
        end
      end

      describe "POST #reregistration" do
        before do
          mock_siq = double("signature")
          allow(mock_siq).to receive(:verify).and_return(true)
          allow(OAuth::Signature).to receive(:build).and_return(mock_siq)
        end

        it "routes to the reregistration action based on header" do
          course_with_teacher_logged_in(active_all: true)
          headers = { "VND-IMS-CONFIRM-URL" => "Routing based on arbitrary headers, Barf!" }.merge(oauth1_header)
          post("/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: "sad times", headers:)
          expect(controller.params[:action]).to eq "re_reg"
        end

        it "checks for valid oauth signatures" do
          mock_siq = double("signature")
          allow(mock_siq).to receive(:verify).and_return(false)
          allow(OAuth::Signature).to receive(:build).and_return(mock_siq)
          course_with_teacher_logged_in(active_all: true)
          headers = { "VND-IMS-CONFIRM-URL" => "Routing based on arbitrary headers, Barf!" }.merge(oauth1_header)
          response = post("/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: "sad times", headers:)
          expect(response).to eq 401
        end

        it "updates the tool proxy update payload" do
          mock_siq = double("signature")
          allow(mock_siq).to receive(:verify).and_return(true)
          allow(OAuth::Signature).to receive(:build).and_return(mock_siq)
          course_with_teacher_logged_in(active_all: true)

          fixture_file = Rails.root.join("spec/fixtures/lti/tool_proxy.json")
          tool_proxy_fixture = JSON.parse(fixture_file.read)

          tcp_url = polymorphic_url([@course.account, :tool_consumer_profile])
          tool_proxy_fixture["tool_consumer_profile"] = tcp_url

          headers = { "VND-IMS-CONFIRM-URL" => "Routing based on arbitrary headers, Barf!" }.merge(oauth1_header)
          response = post("/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: tool_proxy_fixture.to_json, headers:)

          expect(response).to eq 201

          tool_proxy.reload
          expect(tool_proxy.update_payload).to eq({
                                                    acknowledgement_url: "Routing based on arbitrary headers, Barf!",
                                                    payload: tool_proxy_fixture
                                                  })
        end

        it "Errors on invalid payload" do
          mock_siq = double("signature")
          allow(mock_siq).to receive(:verify).and_return(true)
          allow(OAuth::Signature).to receive(:build).and_return(mock_siq)
          course_with_teacher_logged_in(active_all: true)
          headers = { "VND-IMS-CONFIRM-URL" => "Routing based on arbitrary headers, Barf!" }.merge(oauth1_header)
          response = post("/api/lti/accounts/#{@course.account.id}/tool_proxy.json", params: "sad times", headers:)
          expect(response).to eq 400

          tool_proxy.reload
          expect(tool_proxy.update_payload).to be_nil
        end
      end
    end
  end
end

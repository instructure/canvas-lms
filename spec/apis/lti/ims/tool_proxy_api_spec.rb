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
require File.expand_path(File.dirname(__FILE__) + '/../lti2_api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require_dependency "lti/ims/tool_proxy_controller"

module Lti
  module Ims
    describe ToolProxyController, type: :request do
      include_context 'lti2_api_spec_helper'

      let(:account) { Account.new }
      let(:product_family) do
        ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account)
      end
      let(:tool_proxy) do
        ToolProxy.create!(
          context: account,
          guid: SecureRandom.uuid,
          shared_secret: 'abc',
          product_family: product_family,
          product_version: '1',
          workflow_state: 'disabled',
          raw_data: {'proxy' => 'value'},
          lti_version: '1'
        )
      end

      describe "Get #show" do

        before(:each) do
          OAuth::Signature.stubs(:build).returns(mock(verify: true))
          OAuth::Helper.stubs(:parse_header).returns({'oauth_consumer_key' => 'key'})
        end

        it 'the tool proxy raw data' do
          get "/api/lti/tool_proxy/#{tool_proxy.guid}", tool_proxy_guid: tool_proxy.guid
          expect(JSON.parse(body)).to eq tool_proxy.raw_data
        end

        it 'has the correct content-type' do
          get "/api/lti/tool_proxy/#{tool_proxy.guid}", tool_proxy_guid: tool_proxy.guid
          expect(response.headers['Content-Type']).to include 'application/vnd.ims.lti.v2.toolproxy+json'
        end

      end

      describe "POST #create" do

        before(:each) do
          OAuth::Signature.stubs(:build).returns(mock(verify: true))
          OAuth::Helper.stubs(:parse_header).returns({'oauth_consumer_key' => 'key'})
          Lti::RegistrationRequestService.stubs(:retrieve_registration_password).returns('password')
        end

        it 'returns a tool_proxy id object' do
          course_with_teacher_logged_in(:active_all => true)
          tool_proxy_fixture = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))
          json = JSON.parse(tool_proxy_fixture)
          json[:format] = 'json'
          json[:account_id] = @course.account.id
          headers = {'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json'}
          response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", tool_proxy_fixture, headers
          expect(response).to eq 201
          expect(JSON.parse(body).keys).to match_array ["@context", "@type", "@id", "tool_proxy_guid"]
        end

        it 'has the correct content-type' do
          course_with_teacher_logged_in(:active_all => true)
          tool_proxy_fixture = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))
          headers = {'CONTENT_TYPE' => 'application/vnd.ims.lti.v2.toolproxy+json', 'ACCEPT' => 'application/vnd.ims.lti.v2.toolproxy.id+json'}
          post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", tool_proxy_fixture, headers
          expect(response.headers['Content-Type']).to include 'application/vnd.ims.lti.v2.toolproxy.id+json'
        end

        it 'returns an error message' do
          course_with_teacher_logged_in(:active_all => true)
          tool_proxy_fixture = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))
          tp = IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
          tp.tool_profile.resource_handlers.first.messages.first.enabled_capability = ['extra_capability']
          headers = {'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json'}
          response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", tp.to_json, headers
          expect(response).to eq 400
          expect(JSON.parse(body)).to eq({"error" => "Invalid Capabilities"})
        end

        it 'accepts split secret' do
          course_with_teacher_logged_in(:active_all => true)
          #tool_proxy_fixture = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))
          tool_proxy_fixture = JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json')))
          tool_proxy_fixture[:enabled_capability] = ['OAuth.splitSecret']
          tool_proxy_fixture["security_contract"].delete("shared_secret")
          tool_proxy_fixture["security_contract"]["tp_half_shared_secret"] = SecureRandom.hex(128)
          headers = {'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json'}
          response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", tool_proxy_fixture.to_json, headers
          expect(response).to eq 201
          expect(JSON.parse(body).keys).to match_array ["@context", "@type", "@id", "tool_proxy_guid", "tc_half_shared_secret"]
        end
      end

      describe "POST #create with JWT access token" do
        it 'accepts valid JWT access tokens' do
          course_with_teacher_logged_in(:active_all => true)
          tool_proxy_fixture = File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))
          json = JSON.parse(tool_proxy_fixture)
          json[:format] = 'json'
          json[:account_id] = @course.account.id
          response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", tool_proxy_fixture, dev_key_request_headers
          expect(response).to eq 201
        end
      end

      describe "POST #reregistration" do

        before(:each) do
          mock_siq = mock('signature')
          mock_siq.stubs(:verify).returns(true)
          OAuth::Signature.stubs(:build).returns(mock_siq)

        end

        let(:auth_header) do
          {
              'HTTP_AUTHORIZATION' => "OAuth
                oauth_consumer_key=\"#{tool_proxy.guid}\",
                oauth_signature_method=\"HMAC-SHA1\",
                oauth_signature=\"not_a_sig\",
                oauth_timestamp=\"137131200\",
                oauth_nonce=\"4572616e48616d6d65724c61686176\",
                oauth_version=\"1.0\" ".gsub(/\s+/, ' ')
          }
        end

        it "routes to the reregistration action based on header" do
          course_with_teacher_logged_in(:active_all => true)
          headers = {'VND-IMS-CONFIRM-URL' => 'Routing based on arbitrary headers, Barf!'}.merge(auth_header)
          post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", 'sad times', headers
          expect(controller.params[:action]).to eq 're_reg'
        end

        it 'checks for valid oauth signatures' do
          mock_siq = mock('signature')
          mock_siq.stubs(:verify).returns(false)
          OAuth::Signature.stubs(:build).returns(mock_siq)
          course_with_teacher_logged_in(:active_all => true)
          headers = {'VND-IMS-CONFIRM-URL' => 'Routing based on arbitrary headers, Barf!'}.merge(auth_header)
          response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", 'sad times', headers
          expect(response).to eq 401
        end

        it 'updates the tool proxy update payload' do
          mock_siq = mock('signature')
          mock_siq.stubs(:verify).returns(true)
          OAuth::Signature.stubs(:build).returns(mock_siq)
          course_with_teacher_logged_in(:active_all => true)

          fixture_file = File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json')
          tool_proxy_fixture = JSON.parse(File.read(fixture_file))

          tcp_url = polymorphic_url([@course.account, :tool_consumer_profile],
                                    tool_consumer_profile_id: Lti::ToolConsumerProfileCreator::TCP_UUID)
          tool_proxy_fixture["tool_consumer_profile"] = tcp_url

          headers = {'VND-IMS-CONFIRM-URL' => 'Routing based on arbitrary headers, Barf!'}.merge(auth_header)
          response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", tool_proxy_fixture.to_json, headers

          expect(response).to eq 200

          tool_proxy.reload
          expect(tool_proxy.update_payload).to eq({
              :acknowledgement_url => "Routing based on arbitrary headers, Barf!",
              :payload => tool_proxy_fixture
          })
        end

        it 'Errors on invalid payload' do
          mock_siq = mock('signature')
          mock_siq.stubs(:verify).returns(true)
          OAuth::Signature.stubs(:build).returns(mock_siq)
          course_with_teacher_logged_in(:active_all => true)
          headers = {'VND-IMS-CONFIRM-URL' => 'Routing based on arbitrary headers, Barf!'}.merge(auth_header)
          response = post "/api/lti/accounts/#{@course.account.id}/tool_proxy.json", 'sad times', headers
          expect(response).to eq 400

          tool_proxy.reload
          expect(tool_proxy.update_payload).to be_nil
        end
      end
    end
  end
end

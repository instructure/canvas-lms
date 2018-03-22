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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_dependency "lti/tool_proxy_validator.rb"

module Lti
  describe ToolProxyValidator do

    subject(:tool_proxy_validator) {ToolProxyValidator.new(tool_proxy: tool_proxy, tool_consumer_profile: nil)}
    let(:tp_validator) {double("tp_validator")}
    let(:tool_proxy) do
      tp = double("tool_proxy")
      allow(tp).to receive(:tool_profile).and_return(tool_profile)
      allow(tp).to receive(:enabled_capabilities).and_return(enabled_capabilities)
      tp
    end
    let(:tool_profile) do
      tp = double("tool_profile")
      allow(tp).to receive(:security_profiles).and_return(security_profiles)
      tp
    end
    let(:enabled_capabilities) {[]}
    let(:security_profiles) {[]}
    let(:invalid_services_error_messages) {{ invalid_services: { "some_content_id" => 'PUT' } }}
    let(:invalid_security_contract_error_messages) {{ invalid_security_contract: { error: 'message' } }}
    let(:invalid_security_profile_error_messages) {{ invalid_security_profiles: ['error'] }}
    let(:invalid_capability_error_messages) do
      {
        invalid_message_handlers: {
          resource_handlers: [{
                                messages: [{ invalid_capabilities: ['error'] }]
                              }]
        } }
    end
    before :each do
      allow(tp_validator).to receive(:tool_consumer_profile=)
      allow(tp_validator).to receive(:errors)
      allow(IMS::LTI::Services::ToolProxyValidator).to receive(:new).and_return(tp_validator)
    end

    describe '#errors' do
      it 'returns invalid_service errors' do
        allow(tp_validator).to receive(:errors).and_return(invalid_services_error_messages)
        expect(tool_proxy_validator.errors).to eq(invalid_services: [{ :id => "some_content_id", :actions => "PUT" }])
      end

      it 'returns invalid_capability errors' do
        allow(tp_validator).to receive(:errors).and_return(invalid_capability_error_messages)
        expect(tool_proxy_validator.errors).to eq({ :invalid_capabilities => ["error"] })
      end

      it 'returns invalid_security_contract errors' do
        allow(tp_validator).to receive(:errors).and_return(invalid_security_contract_error_messages)
        expect(tool_proxy_validator.errors).to eq({ :invalid_security_contract => ["message"] })
      end

      it 'returns invalid_security_profiles errors' do
        allow(tp_validator).to receive(:errors).and_return(invalid_security_profile_error_messages)
        expect(tool_proxy_validator.errors).to eq({ :invalid_security_profiles => ["error"] })

      end

    end

    describe '#validate!' do
      it 'raises an error if there are invalid_service errors' do
        allow(tp_validator).to receive(:errors).and_return(invalid_services_error_messages)
        expect {tool_proxy_validator.validate!}.to raise_error Lti::Errors::InvalidToolProxyError, 'Invalid Services'
      end

      it 'raises an error if there are invalid_capability errors' do
        allow(tp_validator).to receive(:errors).and_return(invalid_capability_error_messages)
        expect {tool_proxy_validator.validate!}.to raise_error Lti::Errors::InvalidToolProxyError, 'Invalid Capabilities'
      end

      it 'raises an error if there are invalid_security_contract errors' do
        allow(tp_validator).to receive(:errors).and_return(invalid_security_contract_error_messages)
        expect {tool_proxy_validator.validate!}.to raise_error Lti::Errors::InvalidToolProxyError, 'Invalid SecurityContract'
      end

      it 'raises an error if there are invalid_security_profiles errors' do
        allow(tp_validator).to receive(:errors).and_return(invalid_security_profile_error_messages)
        expect {tool_proxy_validator.validate!}.to raise_error Lti::Errors::InvalidToolProxyError, 'Invalid SecurityProfiles'
      end

      context 'restricted security profiles' do

        let(:access_token_profile) do
          sp = double("oauth2_access_token_ws_security")
          allow(sp).to receive(:security_profile_name).and_return('oauth2_access_token_ws_security')
          sp
        end
        let(:jwt_ws_profile) do
          sp = double("lti_jwt_ws_security")
          allow(sp).to receive(:security_profile_name).and_return('lti_jwt_ws_security')
          sp
        end
        let(:oauth_hash_profile) do
          sp = double("lti_oauth_hash_message_security")
          allow(sp).to receive(:security_profile_name).and_return('lti_oauth_hash_message_security')
          sp
        end

        before(:each) do
          allow(tp_validator).to receive(:errors).and_return({})
        end

        it 'raises an error if oauth2_access_token_ws_security is used without split secret' do
          security_profiles << access_token_profile
          expect {tool_proxy_validator.validate!}.to raise_error Lti::Errors::InvalidToolProxyError, 'Restricted SecurityProfiles'
        end

        it 'raises an error if lti_jwt_ws_security is used without split secret' do
          security_profiles << jwt_ws_profile
          expect {tool_proxy_validator.validate!}.to raise_error Lti::Errors::InvalidToolProxyError, 'Restricted SecurityProfiles'
        end

        it 'does not raise an error split_secret is present' do
          security_profiles << jwt_ws_profile
          enabled_capabilities << 'Security.splitSecret'
          expect {tool_proxy_validator.validate!}.not_to raise_error
        end

        it 'does not raise an error for lti_oauth_hash_message_security profile' do
          security_profiles << oauth_hash_profile
          expect {tool_proxy_validator.validate!}.not_to raise_error
        end

      end
    end
  end
end

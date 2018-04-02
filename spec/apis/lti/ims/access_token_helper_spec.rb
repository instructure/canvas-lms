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

require File.expand_path(File.dirname(__FILE__) + '/../lti2_api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../sharding_spec_helper')
require_dependency "lti/ims/access_token_helper"
require 'json/jwt'

module Lti
  module Ims
    describe AccessTokenHelper, type: :controller do
      specs_require_sharding
      include_context 'lti2_api_spec_helper'

      let(:service_name) { 'vnd.Canvas.CustomSecurity' }

      controller(ApplicationController) do
        include Lti::Ims::AccessTokenHelper
        before_action :authorized_lti2_tool

        def index
          head 200
        end

        def lti2_service_name
          'vnd.Canvas.CustomSecurity'
        end

      end

      it 'requires an access token' do
        get :index, format: :json
        expect(response.code).to eq '401'
      end

      it 'decrypts the access token' do
        @request.headers.merge!(request_headers)
        get :index, format: :json
        expect(assigns[:_access_token].to_s).to eq access_token.to_s
      end

      it 'decrypts access token when signed with dev key' do
        @request.headers.merge!(dev_key_request_headers)
        get :index, format: :json
        expect(assigns[:_access_token].to_s).to eq dev_key_access_token.to_s
      end

      it 'allows the request to go through' do
        @request.headers.merge!(request_headers)
        get :index, format: :json
        expect(response.code).to eq '200'
      end

      it 'requires an active tool proxy id signed with share secret' do
        @request.headers.merge!(request_headers)
        tool_proxy.workflow_state = 'disabled'
        tool_proxy.save!
        get :index, format: :json
        expect(response.code).to eq '401'
      end

      it 'requires an active developer key when signed with dev key' do
        @request.headers.merge!(dev_key_request_headers)
        developer_key.destroy!
        get :index, format: :json
        expect(response.code).to eq '401'
      end

      it 'requires the developer key to be active' do
        @request.headers.merge!(request_headers)
        developer_key.deactivate
        get :index, format: :json
        expect(response.code).to eq '401'
      end

      it 'requires the defined service to be in the ToolProxy security contract' do
        @request.headers.merge!(request_headers)
        ims_tp = IMS::LTI::Models::ToolProxy.from_json(tool_proxy.raw_data)
        ims_tp.security_contract.tool_service = nil
        tool_proxy.raw_data = ims_tp.to_json
        tool_proxy.save!
        get :index, format: :json
        expect(response.code).to eq '401'
      end

      it 'requires the http method to be in the security contract' do
        @request.headers.merge!(request_headers)
        ims_tp = IMS::LTI::Models::ToolProxy.from_json(tool_proxy.raw_data)
        service = ims_tp.security_contract.tool_services.first
        service.action = nil
        tool_proxy.raw_data = ims_tp.to_json
        tool_proxy.save!
        get :index, format: :json
        expect(response.code).to eq '401'
      end

      describe "#bearer_token" do
        let(:access_token_helper){ subject }

        it 'returns the bearer token for auth header' do
          @request.headers['Authorization'] = "Bearer #{dev_key_access_token.to_s}"
          expect(access_token_helper.oauth2_request?).to be_truthy
        end
      end

      describe "#tool_proxy" do
        let(:access_token_helper){ subject }
        it 'returns the bearer token for auth header' do
          @request.headers.merge!(request_headers)
          expect(access_token_helper.tool_proxy).to be_truthy
        end
      end

    end
  end
end

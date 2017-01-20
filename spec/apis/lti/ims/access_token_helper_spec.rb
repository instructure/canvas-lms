require File.expand_path(File.dirname(__FILE__) + '/../lti2_api_spec_helper')
require_dependency "lti/ims/access_token_helper"
require 'json/jwt'

module Lti
  module Ims
    describe AccessTokenHelper, type: :controller do
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

      it 'allows the request to go through' do
        @request.headers.merge!(request_headers)
        get :index, format: :json
        expect(response.code).to eq '200'
      end

      it 'requires an active tool proxy' do
        @request.headers.merge!(request_headers)
        tool_proxy.workflow_state = 'disabled'
        tool_proxy.save!
        get :index, format: :json
        expect(response.code).to eq '401'
      end

      it 'requires an active developer key' do
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


    end
  end
end

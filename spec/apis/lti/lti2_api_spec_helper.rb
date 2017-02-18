require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../apis/api_spec_helper')

RSpec.shared_context "lti2_api_spec_helper", :shared_context => :metadata do
  include_context 'lti2_spec_helper'
  let(:access_token) do
    aud = host rescue (@request || request).host
    Lti::Oauth2::AccessToken.create_jwt(aud: aud, sub: tool_proxy.guid)
  end
  let(:request_headers) { {Authorization: "Bearer #{access_token}"} }
  let(:service_name) {controller.lti2_service_name}
  let(:raw_data) do
    rsp = IMS::LTI::Models::RestServiceProfile.new(
      service: "http://example.com/endpoint##{service_name}",
      action: %w(get put delete post)
    )
    ims_tp = IMS::LTI::Models::ToolProxy.new
    security_contract = IMS::LTI::Models::SecurityContract.new(tool_service: rsp)
    ims_tp.security_contract = security_contract
    ims_tp.enabled_capability = ['Security.splitSecret']
    ims_tp.as_json
  end
  let(:tool_proxy) do
    Lti::ToolProxy.create!(
      context: account,
      guid: SecureRandom.uuid,
      shared_secret: 'abc',
      product_family: product_family,
      product_version: '1',
      workflow_state: 'active',
      raw_data: raw_data.as_json,
      lti_version: '1'
    )
  end
end

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

require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../apis/api_spec_helper')

RSpec.shared_context "lti2_api_spec_helper", :shared_context => :metadata do
  include_context 'lti2_spec_helper'
  let(:developer_key) { DeveloperKey.create! }
  let(:dev_key_access_token) do
    aud = host rescue (@request || request).host
    Lti::Oauth2::AccessToken.create_jwt(aud: aud, sub: developer_key.global_id)
  end
  let(:access_token) do
    aud = host rescue (@request || request).host
    file_host, _ = HostUrl.file_host_with_shard(account)
    aud = [aud, file_host]
    Lti::Oauth2::AccessToken.create_jwt(aud: aud, sub: tool_proxy.guid)
  end
  let(:request_headers) { {Authorization: "Bearer #{access_token}"} }
  let(:dev_key_request_headers) { {Authorization: "Bearer #{dev_key_access_token}"} }
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
    tp = Lti::ToolProxy.create!(
      context: account,
      guid: SecureRandom.uuid,
      shared_secret: 'abc',
      product_family: product_family,
      product_version: '1',
      workflow_state: 'active',
      raw_data: raw_data.as_json,
      lti_version: '1'
    )
    Lti::ToolProxyBinding.where(context_id: account, context_type: account.class.to_s,
                                tool_proxy_id: tp).first_or_create!
    tp
  end
end

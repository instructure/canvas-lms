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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

RSpec.shared_context "lti2_spec_helper", :shared_context => :metadata do

  let(:account) { Account.create! }
  let(:course) { Course.create!(account: account) }
  let(:developer_key) {DeveloperKey.create!(redirect_uri: 'http://www.example.com/redirect')}
  let(:product_family) do
    Lti::ProductFamily.create!(
      vendor_code: '123',
      product_code: 'abc',
      vendor_name: 'acme',
      root_account: account,
      developer_key: developer_key
    )
  end
  let(:tool_proxy) do
    tp = Lti::ToolProxy.create!(
      context: account,
      guid: SecureRandom.uuid,
      shared_secret: 'abc',
      product_family: product_family,
      product_version: '1',
      workflow_state: 'active',
      raw_data: {'enabled_capability' => ['Security.splitSecret']},
      lti_version: '1'
    )
    Lti::ToolProxyBinding.where(context_id: account, context_type: account.class.to_s,
                                tool_proxy_id: tp).first_or_create!
    tp
  end
  let(:resource_handler) do
    Lti::ResourceHandler.create!(
      resource_type_code: 'code',
      name: 'resource name',
      tool_proxy: tool_proxy
    )
  end
  let(:message_handler) do
    Lti::MessageHandler.create!(
      message_type: 'message_type',
      launch_path: 'https://samplelaunch/blti',
      resource_handler: resource_handler,
      tool_proxy: tool_proxy
    )
  end
  let(:tool_proxy_binding) {
    Lti::ToolProxyBinding.where(context_id: account, context_type: account.class.to_s,
                                tool_proxy_id: tool_proxy).first_or_create!
  }

end

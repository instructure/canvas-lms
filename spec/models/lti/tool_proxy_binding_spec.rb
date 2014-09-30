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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

module Lti
describe ToolProxyBinding do

  let(:account) {Account.new}
  let(:tool_proxy) {ToolProxy.new}

  describe 'validations' do

    before(:each) do
      subject.context = account
      subject.tool_proxy = tool_proxy
    end

    it 'requires a context' do
      subject.context = nil
      subject.save
      subject.errors.first.should == [:context, "can't be blank"]
    end

    it 'requires a tool_proxy' do
      subject.tool_proxy = nil
      subject.save
      subject.errors.first.should == [:tool_proxy, "can't be blank"]
    end

    context 'tool_settings' do
      let (:account) { Account.create }
      let (:product_family) { ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account) }
      let (:resource_handler) { ResourceHandler.create(resource_type_code: 'code', name: 'resource name', tool_proxy: tool_proxy) }
      let (:message_handler) { MessageHandler.create(message_type: 'message_type', launch_path:'https://samplelaunch/blti', resource: resource_handler)}
      let (:tool_proxy) { ToolProxy.create(
        shared_secret: 'shared_secret',
        guid: 'guid',
        product_version: '1.0beta',
        lti_version: 'LTI-2p0',
        product_family: product_family,
        context: account,
        workflow_state: 'active',
        raw_data: 'some raw data'
      ) }
      subject{ tool_proxy.bindings.create(context:account)}

      it 'can have a tool setting' do
        subject.create_tool_setting(custom: {name: :foo})
        subject.tool_setting[:custom].should == {name: :foo}

      end
      
    end

  end

  end
end

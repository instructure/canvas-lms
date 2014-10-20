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
  describe ToolSetting do
    let (:account) { Account.create }
    let (:product_family) { ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account) }
    let (:resource_handler) { ResourceHandler.create(resource_type_code: 'code', name: 'resource name', tool_proxy: tool_proxy) }
    let (:message_handler) { MessageHandler.create(message_type: 'message_type', launch_path: 'https://samplelaunch/blti', resource: resource_handler) }
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

    it 'can be associated with a resource link' do
      subject.tool_proxy = tool_proxy
      subject.context = account
      subject.resource_link_id = '123456'
      subject.save.should == true
    end

    it 'fails if there is a resource_link_id and no context' do
      subject.tool_proxy = tool_proxy
      subject.resource_link_id = '123456'
      subject.save.should == false
      subject.errors.first.should == [:context, "can't be blank"]
    end


  end
end
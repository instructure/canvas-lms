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
  describe MessageHandler do

    let (:account) { Account.create }
    let (:product_family) { ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account) }

    describe 'validations' do
      before(:each) do
        subject.message_type = 'message_type'
        subject.launch_path = 'launch_path'
        subject.resource_handler = ResourceHandler.new
      end

      it 'requires the message type' do
        subject.message_type = nil
        subject.save
        subject.errors.first.should == [:message_type, "can't be blank"]
      end

      it 'requires the launch path' do
        subject.launch_path = nil
        subject.save
        subject.errors.first.should == [:launch_path, "can't be blank"]
      end

      it 'requires a resource_handler' do
        subject.resource_handler = nil
        subject.save
        subject.errors.first.should == [:resource_handler, "can't be blank"]
      end
    end

    describe 'scope #message_type' do

      it 'returns all message_handlers for a message_type' do
        mh1 = create_message_handler
        mh2 = create_message_handler
        mh3 = create_message_handler(create_resource_handler, message_type: 'content_item')

        message_handlers = described_class.by_message_types('basic-lti-launch-request')
        message_handlers.count.should == 2
      end

      it 'returns all message_handlers for mutlipe message types' do
        rh = create_resource_handler
        mh1 = create_message_handler(rh)
        mh2 = create_message_handler(rh, message_type: 'other_type')
        mh3 = create_message_handler(rh, message_type: 'content_item')

        message_handlers = described_class.by_message_types('basic-lti-launch-request', 'other_type')
        message_handlers.count.should == 2
      end

    end

    describe 'scope #for_tool_proxies' do


      it 'returns all message_handlers for a tool proxy' do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        message_handlers = (1..3).map do |code|
          rh = create_resource_handler(tp, resource_type_code: code)
          create_message_handler(rh)
        end
        Set.new(described_class.for_context(account)).should == Set.new(message_handlers)
      end

      it 'returns all message_handlers for multiple tool_proxy' do
        tool_proxies = (1..3).map {|_| create_tool_proxy}
        message_handlers = tool_proxies.map do |tp|
          tp.bindings.create(context: account)
          rh = create_resource_handler(tp)
          create_message_handler(rh)
        end
        Set.new(described_class.for_context(account)).should == Set.new(message_handlers)
      end

    end


    def create_tool_proxy(opts = {})
      default_opts = {
        context: account,
        shared_secret: 'shared_secret',
        guid: SecureRandom.uuid,
        product_version: '1.0beta',
        lti_version: 'LTI-2p0',
        product_family: product_family,
        workflow_state: 'active',
        raw_data: 'some raw data'
      }
      ToolProxy.create(default_opts.merge(opts))
    end

    def create_resource_handler(tool_proxy = create_tool_proxy, opts = {})
      default_opts = {resource_type_code: 'code', name: 'resource name', tool_proxy: tool_proxy}
      ResourceHandler.create(default_opts.merge(opts))
    end

    def create_message_handler(resource_handler = create_resource_handler, opts = {})
      default_ops = {message_type: 'basic-lti-launch-request', launch_path: 'https://samplelaunch/blti', resource_handler: resource_handler}
      MessageHandler.create(default_ops.merge(opts))
    end

  end
end
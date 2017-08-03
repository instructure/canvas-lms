#
# Copyright (C) 2011 - present Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require_dependency "lti/resource_handler"

module Lti
  describe ResourceHandler do
    include_context 'lti2_spec_helper'

    describe 'validations' do
      before(:each) do
        resource_handler.resource_type_code = 'code'
        resource_handler.name = 'name'
        resource_handler.tool_proxy = ToolProxy.new
      end

      it 'requires the name' do
        resource_handler.name = nil
        resource_handler.save
        expect(resource_handler.errors.first).to eq [:name, "can't be blank"]
      end

      it 'requires a tool proxy' do
        resource_handler.tool_proxy = nil
        resource_handler.save
        expect(resource_handler.errors.first).to eq [:tool_proxy, "can't be blank"]
      end
    end

    describe '#find_message_by_type' do
      let(:message_type) { 'custom-message-type' }

      before do
        message_handler.update_attributes(message_type: message_type)
        resource_handler.update_attributes(message_handlers: [message_handler])
      end

      it 'returns the message handler with the specified type' do
        expect(resource_handler.find_message_by_type(message_type)).to eq message_handler
      end

      it 'does not return messages with a different type' do
        message_handler.update_attributes(message_type: 'different-type')
        expect(resource_handler.find_message_by_type(message_type)).to be_nil
      end
    end

    describe '#self.by_product_family' do
      before { resource_handler.update_attributes(tool_proxy: tool_proxy) }

      it 'returns resource handlers with specified product family and context' do
        resource_handlers = ResourceHandler.by_product_family([product_family], tool_proxy.context)
        expect(resource_handlers).to include resource_handler
      end

      it 'does not return resource handlers with different product family' do
        pf = product_family.dup
        pf.update_attributes(product_code: SecureRandom.uuid)
        resource_handlers = ResourceHandler.by_product_family([pf], tool_proxy.context)
        expect(resource_handlers).not_to include resource_handler
      end

      it 'does not return resource handlers with different context' do
        a = Account.create!
        resource_handlers = ResourceHandler.by_product_family([product_family], a)
        expect(resource_handlers).not_to include resource_handler
      end
    end

    describe '#self.by_resource_codes' do
      let(:jwt_body) do
        {
          vendor_code: product_family.vendor_code,
          product_code: product_family.product_code,
          resource_type_code: resource_handler.resource_type_code
        }
      end

      it 'finds resource handlers specified in link id JWT' do
        resource_handlers = ResourceHandler.by_resource_codes(vendor_code: jwt_body[:vendor_code],
                                                              product_code: jwt_body[:product_code],
                                                              resource_type_code: jwt_body[:resource_type_code],
                                                              context: tool_proxy.context)
        expect(resource_handlers).to match_array([resource_handler])
      end

      it 'considers all matching product families, not just the first' do
        k = DeveloperKey.new
        pf = Lti::ProductFamily.create!(
          product_code: product_family.product_code,
          vendor_code: product_family.vendor_code,
          vendor_name: 'test',
          root_account: account,
          developer_key: k
        )

        tool_proxy.product_family = pf
        tool_proxy.save!

        resource_handlers = ResourceHandler.by_resource_codes(vendor_code: jwt_body[:vendor_code],
                                                              product_code: jwt_body[:product_code],
                                                              resource_type_code: jwt_body[:resource_type_code],
                                                              context: tool_proxy.context)
        expect(resource_handlers).to match_array([resource_handler])
      end

      it 'does not return resource handlers with the wrong resource type code' do
        jwt_body[:resource_type_code] = 'banana'
        resource_handlers = ResourceHandler.by_resource_codes(vendor_code: jwt_body[:vendor_code],
                                                              product_code: jwt_body[:product_code],
                                                              resource_type_code: jwt_body[:resource_type_code],
                                                              context: tool_proxy.context)
        expect(resource_handlers).to be_blank
      end

      it 'does not return resource handlers with different context' do
        a = Account.create!
        resource_handlers = ResourceHandler.by_resource_codes(vendor_code: jwt_body[:vendor_code],
                                                              product_code: jwt_body[:product_code],
                                                              resource_type_code: jwt_body[:resource_type_code],
                                                              context: a)
        expect(resource_handlers).to be_blank
      end
    end

    describe '#find_or_create_tool_setting' do
      before do
        message_handler.update_attributes(message_type: MessageHandler::BASIC_LTI_LAUNCH_REQUEST)
        resource_handler.message_handlers = [message_handler]
        resource_handler.save!
        user_session(account_admin_user)
      end

      it 'creates a new tool setting if one with the existing resource_link_id does not exist' do
        expected_id = message_handler.build_resource_link_id(context: tool_proxy.context)
        expect(resource_handler.find_or_create_tool_setting.resource_link_id).to eq expected_id
      end

      it 'reuses a tool setting if one with the same resource_link_id exists' do
        tool_setting = resource_handler.find_or_create_tool_setting
        expect(resource_handler.find_or_create_tool_setting).to eq tool_setting
      end

      it 'allows changing the settings of an originality report without affecting others' do
        link_fragment = SecureRandom.uuid
        resource_handler.find_or_create_tool_setting
        setting_two = resource_handler.find_or_create_tool_setting(link_fragment: link_fragment)
        setting_two.update_attributes(resource_url: 'http://www.test.com')
        expect(resource_handler.find_or_create_tool_setting.resource_url).to be_nil
      end
    end
  end
end

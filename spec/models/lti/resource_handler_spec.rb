# frozen_string_literal: true

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
require_relative "../../lti2_spec_helper"

module Lti
  describe ResourceHandler do
    include_context "lti2_spec_helper"

    describe "validations" do
      before do
        resource_handler.resource_type_code = "code"
        resource_handler.name = "name"
        resource_handler.tool_proxy = ToolProxy.new
      end

      it "requires the name" do
        resource_handler.name = nil
        resource_handler.save
        expect(resource_handler.errors.first).to eq [:name, "can't be blank"]
      end

      it "requires a tool proxy" do
        resource_handler.tool_proxy = nil
        resource_handler.save
        expect(resource_handler.errors.first).to eq [:tool_proxy, "can't be blank"]
      end
    end

    describe "#find_message_by_type" do
      let(:message_type) { "custom-message-type" }

      before do
        message_handler.update(message_type:)
        resource_handler.update(message_handlers: [message_handler])
      end

      it "returns the message handler with the specified type" do
        expect(resource_handler.find_message_by_type(message_type)).to eq message_handler
      end

      it "does not return messages with a different type" do
        message_handler.update(message_type: "different-type")
        expect(resource_handler.find_message_by_type(message_type)).to be_nil
      end
    end

    describe "#self.by_product_family" do
      before { resource_handler.update(tool_proxy:) }

      it "returns resource handlers with specified product family and context" do
        resource_handlers = ResourceHandler.by_product_family([product_family], tool_proxy.context)
        expect(resource_handlers).to include resource_handler
      end

      it "does not return resource handlers with different product family" do
        pf = product_family.dup
        pf.update(product_code: SecureRandom.uuid)
        resource_handlers = ResourceHandler.by_product_family([pf], tool_proxy.context)
        expect(resource_handlers).not_to include resource_handler
      end

      it "does not return resource handlers with different context" do
        a = Account.create!
        resource_handlers = ResourceHandler.by_product_family([product_family], a)
        expect(resource_handlers).not_to include resource_handler
      end
    end

    describe "#self.by_resource_codes" do
      let(:jwt_body) do
        {
          vendor_code: product_family.vendor_code,
          product_code: product_family.product_code,
          resource_type_code: resource_handler.resource_type_code
        }
      end

      it "finds resource handlers specified in link id JWT" do
        resource_handlers = ResourceHandler.by_resource_codes(vendor_code: jwt_body[:vendor_code],
                                                              product_code: jwt_body[:product_code],
                                                              resource_type_code: jwt_body[:resource_type_code],
                                                              context: tool_proxy.context)
        expect(resource_handlers).to match_array([resource_handler])
      end

      it "considers all matching product families, not just the first" do
        k = DeveloperKey.new
        pf = Lti::ProductFamily.create!(
          product_code: product_family.product_code,
          vendor_code: product_family.vendor_code,
          vendor_name: "test",
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

      it "does not return resource handlers with the wrong resource type code" do
        jwt_body[:resource_type_code] = "banana"
        resource_handlers = ResourceHandler.by_resource_codes(vendor_code: jwt_body[:vendor_code],
                                                              product_code: jwt_body[:product_code],
                                                              resource_type_code: jwt_body[:resource_type_code],
                                                              context: tool_proxy.context)
        expect(resource_handlers).to be_blank
      end

      it "does not return resource handlers with different context" do
        a = Account.create!
        resource_handlers = ResourceHandler.by_resource_codes(vendor_code: jwt_body[:vendor_code],
                                                              product_code: jwt_body[:product_code],
                                                              resource_type_code: jwt_body[:resource_type_code],
                                                              context: a)
        expect(resource_handlers).to be_blank
      end
    end
  end
end

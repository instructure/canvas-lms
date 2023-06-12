# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
  describe ToolSetting do
    let(:account) { Account.create }
    let(:product_family) { ProductFamily.create(vendor_code: "123", product_code: "abc", vendor_name: "acme", root_account: account) }
    let(:resource_handler) { ResourceHandler.create(resource_type_code: "code", name: "resource name", tool_proxy:) }
    let(:message_handler) { MessageHandler.create(message_type: "basic-lti-launch-request", launch_path: "https://samplelaunch/blti", resource_handler:) }
    let(:tool_proxy) do
      ToolProxy.create(
        shared_secret: "shared_secret",
        guid: "guid",
        product_version: "1.0beta",
        lti_version: "LTI-2p0",
        product_family:,
        context: account,
        workflow_state: "active",
        raw_data: "some raw data"
      )
    end

    it "can be associated with a resource link" do
      subject.tool_proxy = tool_proxy
      subject.context = account
      subject.resource_link_id = "123456"
      expect(subject.save).to be true
    end

    it "fails if there is a resource_link_id and no context" do
      subject.tool_proxy = tool_proxy
      subject.resource_link_id = "123456"
      expect(subject.save).to be false
      expect(subject.errors.first).to eq [:context, "can't be blank"]
    end

    describe "#custom_settings" do
      before do
        ToolSetting.create(tool_proxy:, context: account, resource_link_id: "abc", custom: { link: :setting, a: 1, b: 2, c: 3 })
        ToolSetting.create(tool_proxy:, context: account, custom: { binding: :setting, a: 1, b: 2, d: 4 })
        ToolSetting.create(tool_proxy:, custom: { proxy: :setting, a: 1, c: 5, d: 4 })
      end

      it "creates the json" do
        expect(ToolSetting.custom_settings(tool_proxy.id, account, "abc")).to eq({ link: :setting, a: 1, b: 2, c: 3, binding: :setting, d: 4, proxy: :setting })
      end
    end

    describe "#message_handler" do
      include_context "lti2_spec_helper"
      let(:tool_setting) { subject }

      before do
        message_handler.update(message_type: MessageHandler::BASIC_LTI_LAUNCH_REQUEST)
        resource_handler.message_handlers = [message_handler]
        resource_handler.save!

        tool_setting.update(resource_type_code: resource_handler.resource_type_code,
                            product_code: product_family.product_code,
                            vendor_code: product_family.vendor_code)
      end

      it "looks up the message handler identified by the codes" do
        expect(tool_setting.message_handler(account)).to eq message_handler
      end
    end
  end
end

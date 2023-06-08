# frozen_string_literal: true

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

RSpec.shared_context "lti2_course_spec_helper", shared_context: :metadata do
  let(:account) { Account.create! }
  let(:course) { Course.create!(account:) }
  let(:developer_key) { DeveloperKey.create!(redirect_uri: "http://www.example.com/redirect") }
  let(:product_family) do
    Lti::ProductFamily.create!(
      vendor_code: "123",
      product_code: "abc",
      vendor_name: "acme",
      root_account: account,
      developer_key:
    )
  end
  let(:tool_proxy) do
    tp = Lti::ToolProxy.create!(
      context: course,
      guid: SecureRandom.uuid,
      shared_secret: "abc",
      product_family:,
      product_version: "1",
      workflow_state: "active",
      raw_data: {
        "enabled_capability" => ["Security.splitSecret"],
        "tool_profile" => {
          "lti_version" => "LTI-2p0",
          "product_instance" => {
            "guid" => "be42ae52-23fe-48f5-a783-40ecc7ef6d5c",
            "product_info" => {
              "product_version" => "1.0",
              "product_family" => {
                "code" => "abc",
                "vendor" => {
                  "code" => "123",
                  "vendor_name" => {
                    "default_value" => "acme"
                  },
                  "description" => {
                    "default_value" => "example vendor"
                  }
                }
              },
              "description" => {
                "default_value" => "example product"
              },
              "product_name" => {
                "default_value" => "learn abc's"
              }
            }
          },
          "base_url_choice" => [
            {
              "default_base_url" => "https://www.samplelaunch.com",
              "selector" => {
                "applies_to" => [
                  "MessageHandler"
                ]
              }
            }
          ],
          "resource_handler" => [
            {
              "resource_type" => {
                "code" => "code"
              },
              "resource_name" => {
                "default_value" => "resource name",
                "key" => ""
              },
              "message" => [
                {
                  "message_type" => "message_type",
                  "path" => "https://www.samplelaunch.com/blti"
                }
              ]
            }
          ],
          "service_offered" => []
        }
      },
      lti_version: "1"
    )
    Lti::ToolProxyBinding.where(context_id: account,
                                context_type: account.class.to_s,
                                tool_proxy_id: tp).first_or_create!
    tp
  end
  let(:resource_handler) do
    Lti::ResourceHandler.create!(
      resource_type_code: "code",
      name: "resource name",
      tool_proxy:
    )
  end
  let(:message_handler) do
    Lti::MessageHandler.create!(
      message_type: Lti::MessageHandler::BASIC_LTI_LAUNCH_REQUEST,
      launch_path: "https://www.samplelaunch.com/blti",
      resource_handler:,
      tool_proxy:
    )
  end
  let(:tool_proxy_binding) do
    Lti::ToolProxyBinding.where(context_id: account,
                                context_type: account.class.to_s,
                                tool_proxy_id: tool_proxy).first_or_create!
  end
end

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

require "lti2_spec_helper"

describe AssignmentConfigurationToolLookup do
  include_context "lti2_spec_helper"

  let(:subscription_service) { class_double(Services::LiveEventsSubscriptionService).as_stubbed_const }
  let(:test_id) { SecureRandom.uuid }
  let(:stub_response) { double(code: 200, parsed_response: { "Id" => test_id }, ok?: true) }
  let(:assignment) { assignment_model(course:) }

  before do
    message_handler.update(capabilities: ["Canvas.placements.similarityDetection"])

    resource_handler.message_handlers << message_handler
    tool_proxy.resources << resource_handler
    tool_proxy.save!
  end

  describe "#lti_tool" do
    it "returns the tool associated by id if present (for backwards compatibility and future LTI 1)" do
      lookup = assignment.assignment_configuration_tool_lookups.create!(
        context_type: "Account",
        tool_id: message_handler.id,
        tool_type: "Lti::MessageHandler"
      )
      expect(lookup.lti_tool).to eq message_handler
    end

    it "returns the message handler associated by lti codes" do
      assignment.tool_settings_tool = message_handler
      assignment.save!
      lookup = assignment.assignment_configuration_tool_lookups.last
      expect(lookup.lti_tool).to eq message_handler
    end
  end

  describe "#resource_codes" do
    let(:expected_hash) do
      {
        product_code: product_family.product_code,
        vendor_code: product_family.vendor_code,
        resource_type_code: resource_handler.resource_type_code
      }
    end

    it "returns the resource codes when the tool is not set but the codes are" do
      lookup = AssignmentConfigurationToolLookup.create!(assignment:, tool: message_handler)
      expect(lookup.resource_codes).to eq expected_hash
    end

    it "returns the resource codes when only the tool_id is set" do
      lookup = AssignmentConfigurationToolLookup.create!(
        assignment:,
        tool_type: "Lti::MessageHandler",
        tool_product_code: product_family.product_code,
        tool_vendor_code: product_family.vendor_code,
        tool_resource_type_code: resource_handler.resource_type_code
      )
      expect(lookup.resource_codes).to eq expected_hash
    end

    it "returns an empty hash when the tool is not a message handler" do
      tool = course.context_external_tools.create!(name: "a", url: "http://www.test.com", consumer_key: "12345", shared_secret: "secret")
      lookup = AssignmentConfigurationToolLookup.create(assignment:, tool:)
      expect(lookup.resource_codes).to eq({})
    end
  end

  describe "#configured_assignments" do
    let(:assignment) do
      a = course.assignments.new(title: "Test Assignment")
      a.workflow_state = "published"
      a.tool_settings_tool = message_handler
      a.save!
      a
    end
    let(:root_account) { Account.create!(name: "root account") }
    let(:account) { Account.create!(name: "account", root_account:) }
    let(:course) { Course.create!(account:) }

    before do
      message_handler.update!(capabilities: [Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2])
      tool_proxy.update!(context: account)
      assignment
    end

    it "finds configured assignments when installed in an account" do
      tool_proxy.update!(context: account)
      expect(AssignmentConfigurationToolLookup.by_tool_proxy(tool_proxy)).to match_array [assignment]
    end

    it "finds configured assignments when installed in a root account" do
      tool_proxy.update!(context: root_account)
      expect(AssignmentConfigurationToolLookup.by_tool_proxy(tool_proxy)).to match_array [assignment]
    end

    it "finds configured assignments when installed in a course" do
      tool_proxy.update!(context: course)
      expect(AssignmentConfigurationToolLookup.by_tool_proxy(tool_proxy)).to match_array [assignment]
    end

    it "handles multiple configured assignments" do
      second_assignment = assignment.dup
      second_assignment.tool_settings_tool = message_handler
      second_assignment.lti_context_id = SecureRandom.uuid
      second_assignment.save!
      tool_proxy.update!(context: root_account)
      expect(AssignmentConfigurationToolLookup.by_tool_proxy(tool_proxy)).to match_array [assignment, second_assignment]
    end
  end

  describe "#webhook_info" do
    it "shows the correct info" do
      lookup = AssignmentConfigurationToolLookup.create!(
        assignment:,
        tool_type: "Lti::MessageHandler",
        tool_product_code: product_family.product_code,
        tool_vendor_code: product_family.vendor_code,
        tool_resource_type_code: resource_handler.resource_type_code
      )
      expect(lookup.webhook_info).to match(
        {
          product_code: lookup.tool_product_code,
          vendor_code: lookup.tool_vendor_code,
          resource_type_code: lookup.tool_resource_type_code,
          tool_proxy_id: tool_proxy.id,
          tool_proxy_created_at: tool_proxy.created_at,
          tool_proxy_updated_at: tool_proxy.updated_at,
          tool_proxy_name: tool_proxy.name,
          tool_proxy_context_type: tool_proxy.context_type,
          tool_proxy_context_id: tool_proxy.context_id,
          subscription_id: tool_proxy.subscription_id
        }
      )
    end
  end
end

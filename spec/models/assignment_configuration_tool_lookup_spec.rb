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

require File.expand_path(File.dirname(__FILE__) + '/../lti2_spec_helper.rb')

describe AssignmentConfigurationToolLookup do
  include_context 'lti2_spec_helper'

  let(:subscription_service){ class_double(Services::LiveEventsSubscriptionService).as_stubbed_const }
  let(:test_id){ 'test-id' }
  let(:stub_response){ double(code: 200, parsed_response: {'Id' => 'test-id'}, ok?: true) }
  let(:assignment){ assignment_model(course: course) }

  before(:each) do
    allow(subscription_service).to receive_messages(available?: true)
    allow(subscription_service).to receive_messages(create_tool_proxy_subscription: stub_response)
    allow(subscription_service).to receive_messages(destroy_tool_proxy_subscription: stub_response)

    message_handler.update_attributes(capabilities: ["Canvas.placements.similarityDetection"])

    resource_handler.message_handlers << message_handler
    tool_proxy.resources << resource_handler
    tool_proxy.save!
  end

  describe '#destroy_subscription' do
    it 'destroys the subscription if it exists' do
      expect(subscription_service).to receive(:destroy_tool_proxy_subscription).with(tool_proxy, 'test-id')
      assignment.tool_settings_tool = message_handler
      assignment.save!
      lookup = assignment.assignment_configuration_tool_lookups.last
      lookup.destroy_subscription
    end

    it 'does not attempt to destroy a subscription if not LTI2 tool' do
      expect(subscription_service).not_to receive(:destroy_tool_proxy_subscription)
      tool = course.context_external_tools.create!(name: "a", url: "http://www.test.com", consumer_key: '12345', shared_secret: 'secret')
      lookup = AssignmentConfigurationToolLookup.create(assignment: assignment, tool: tool)
      lookup.destroy_subscription
    end
  end

  describe '#create_subscription' do
    it 'does not create subscription if tool is not LTI2' do
      tool = course.context_external_tools.create!(name: "a", url: "http://www.test.com", consumer_key: '12345', shared_secret: 'secret')
      assignment.tool_settings_tool = tool
      assignment.save!
      lookup = AssignmentConfigurationToolLookup.where(assignment: assignment, tool: tool).first
      expect(lookup.subscription_id).to be_nil
    end

    it 'creates subscription if the tool is LTI2' do
      assignment.tool_settings_tool = message_handler
      assignment.save!
      lookup = assignment.assignment_configuration_tool_lookups.last
      expect(lookup.subscription_id).to eq(test_id)
    end
  end

  describe '#lti_tool' do
    it 'returns the tool associated by id if present (for backwards compatibility and future LTI 1)' do
      lookup = assignment.assignment_configuration_tool_lookups.create!(
        tool_id: message_handler.id,
        tool_type: 'Lti::MessageHandler'
      )
      expect(lookup.lti_tool).to eq message_handler
    end

    it 'returns the message handler associated by lti codes' do
      assignment.tool_settings_tool = message_handler
      assignment.save!
      lookup = assignment.assignment_configuration_tool_lookups.last
      expect(lookup.lti_tool).to eq message_handler
    end
  end

  describe '#resource_codes' do
    let(:expected_hash) do
      {
        product_code: product_family.product_code,
        vendor_code: product_family.vendor_code,
        resource_type_code: resource_handler.resource_type_code
      }
    end

    it 'returns the resource codes when the tool is not set but the codes are' do
      lookup = AssignmentConfigurationToolLookup.create!(assignment: assignment, tool: message_handler)
      expect(lookup.resource_codes).to eq expected_hash
    end

    it 'returns the resource codes when only the tool_id is set' do
      lookup = AssignmentConfigurationToolLookup.create!(
        assignment: assignment,
        tool_type: 'Lti::MessageHandler',
        tool_product_code: product_family.product_code,
        tool_vendor_code: product_family.vendor_code,
        tool_resource_type_code: resource_handler.resource_type_code
      )
      expect(lookup.resource_codes).to eq expected_hash
    end

    it 'returns an empty hash when the tool is not a message handler' do
      tool = course.context_external_tools.create!(name: "a", url: "http://www.test.com", consumer_key: '12345', shared_secret: 'secret')
      lookup = AssignmentConfigurationToolLookup.create(assignment: assignment, tool: tool)
      expect(lookup.resource_codes).to eq({})
    end
  end

  describe '#configured_assignments' do
    let(:root_account) { Account.create!(name: 'root account') }
    let(:account) { Account.create!(name: 'account', root_account: root_account) }
    let(:course) { Course.create!(account: account) }
    let(:assignment) do
      a = course.assignments.new(title: 'Test Assignment')
      a.workflow_state = 'published'
      a.tool_settings_tool = message_handler
      a.save!
      a
    end

    before do
      allow_any_instance_of(Lti::AssignmentSubscriptionsHelper).to receive(:create_subscription) { SecureRandom.uuid }
      allow_any_instance_of(Lti::AssignmentSubscriptionsHelper).to receive(:destroy_subscription) { {} }
      message_handler.update_attributes(capabilities: [Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2])
      assignment
    end

    it 'finds configured assignments when installed in an account' do
      tool_proxy.update_attributes!(context: account)
      expect(AssignmentConfigurationToolLookup.by_tool_proxy(tool_proxy)).to match_array [assignment]
    end

    it 'finds configured assignments when installed in a root acocunt' do
      tool_proxy.update_attributes!(context: root_account)
      expect(AssignmentConfigurationToolLookup.by_tool_proxy(tool_proxy)).to match_array [assignment]
    end

    it 'finds configured assignments when installed in a course' do
      tool_proxy.update_attributes!(context: course)
      expect(AssignmentConfigurationToolLookup.by_tool_proxy(tool_proxy)).to match_array [assignment]
    end

    it 'handles multiple configured assignments' do
      second_assignment = assignment.dup
      second_assignment.tool_settings_tool = message_handler
      second_assignment.lti_context_id = SecureRandom.uuid
      second_assignment.save!
      tool_proxy.update_attributes!(context: root_account)
      expect(AssignmentConfigurationToolLookup.by_tool_proxy(tool_proxy)).to match_array [assignment, second_assignment]
    end
  end
end

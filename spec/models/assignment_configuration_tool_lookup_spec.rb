require File.expand_path(File.dirname(__FILE__) + '/../lti2_spec_helper.rb')

describe AssignmentConfigurationToolLookup do
  describe '#create_subscription' do
    include_context 'lti2_spec_helper'

    let(:subscription_service){ class_double(Services::LiveEventsSubscriptionService).as_stubbed_const }
    let(:test_id){ 'test-id' }
    let(:stub_response){ double(code: 200, parsed_response: {'Id' => 'test-id'}, ok?: true) }
    let(:assignment){ assignment_model(course: course) }

    before(:each) do
      allow(subscription_service).to receive_messages(available?: true)
      allow(subscription_service).to receive_messages(create_tool_proxy_subscription: stub_response)
      message_handler.update_attributes(capabilities: ["Canvas.placements.similarityDetection"])
      resource_handler.message_handlers << message_handler
      tool_proxy.resources << resource_handler
      tool_proxy.save!
    end

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
      lookup = AssignmentConfigurationToolLookup.where(assignment: assignment, tool: message_handler).first
      expect(lookup.subscription_id).to eq(test_id)
    end
  end
end

require File.expand_path(File.dirname(__FILE__) + '../../../apis/lti/lti2_api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '../../../../lib/lti/assignment_subscriptions_helper')

describe Lti::AssignmentSubscriptionsHelper do
  include_context 'lti2_api_spec_helper'
  let(:test_subscription){ {'RootAccountId' => '1', 'foo' => 'bar'} }
  let(:stub_response){ double(code: 200, body: test_subscription.to_json, parsed_response: {'Id' => 'test-id'}, ok?: true) }
  let(:stub_bad_response){ double(code: 200, body: test_subscription.to_json, parsed_response: {'Id' => 'test-id'}, ok?: false) }
  let(:controller){ double(lti2_service_name: 'vnd.Canvas.foo') }
  let(:submission_event_endpoint){ 'test.com/submission' }
  let(:submission_event_service) do
    {
      'endpoint' => submission_event_endpoint,
      'format' => ['application/json'],
      'action' => ['POST'],
      '@id' => 'http://test.service.com/service#SubmissionEvent',
      '@type' => 'RestService'
    }
  end
  let(:bad_submission_event_service) do
    {
      'format' => ['application/json'],
      'action' => ['POST'],
      '@id' => 'http://test.service.com/service#SubmissionEvent',
      '@type' => 'RestService'
    }
  end

  before(:each) do
    course_with_teacher(active_all: true)
    ss = class_double(Services::LiveEventsSubscriptionService).as_stubbed_const
    allow(ss).to receive_messages(create_tool_proxy_subscription: stub_response)
    allow(ss).to receive_messages(available?: true)

    tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.Canvas.webhooks.root_account.all)
    tool_proxy[:raw_data]['tool_profile'] = {'service_offered' => [submission_event_service]}
    tool_proxy.save!

    @assignment = @course.assignments.create!(name: 'test assignment')
  end

  describe '#create_subscription' do
    let(:subscription_helper){ Lti::AssignmentSubscriptionsHelper.new(@assignment, tool_proxy) }
    before(:each) do
      @assignment.tool_settings_tool = message_handler
      @assignment.save!
    end

    it 'creates a subscription and returns the id' do
      expect(subscription_helper.create_subscription).to eq 'test-id'
    end

    it 'uses the live-event format' do
      expect(subscription_helper.assignment_subscription(@assignment.id)[:Format]).to eq 'caliper'
    end

    it 'uses the https transport type' do
      expect(subscription_helper.assignment_subscription(@assignment.id)[:TransportType]).to eq 'https'
    end

    it 'uses the transport metadata specified by the tool' do
      expect(subscription_helper.assignment_subscription(@assignment.id)[:TransportMetadata]).to eq({'Url' => submission_event_endpoint})
    end

    context 'bad subscription request' do
      before(:each) do
        ss = class_double(Services::LiveEventsSubscriptionService).as_stubbed_const
        allow(ss).to receive_messages(create_tool_proxy_subscription: stub_bad_response)
        allow(ss).to receive_messages(available?: true)
      end

      it "raises 'AssignmentSubscriptionError' if subscription service response is not ok" do
        expect{subscription_helper.create_subscription}.to raise_exception(Lti::AssignmentSubscriptionsHelper::AssignmentSubscriptionError)
      end

      it "raises 'AssignmentSubscriptionError' with error message if service is missing" do
        tool_proxy[:raw_data]['tool_profile'] = {'service_offered' => []}
        expect{subscription_helper.create_subscription}.to raise_exception(Lti::AssignmentSubscriptionsHelper::AssignmentSubscriptionError, 'Plagiarism review tool is missing submission event service')
      end

      it "raises 'AssignmentSubscriptionError' with error message if service is missing endpoint" do
        tool_proxy[:raw_data]['tool_profile'] = {'service_offered' => [bad_submission_event_service]}
        expect{subscription_helper.create_subscription}.to raise_exception(Lti::AssignmentSubscriptionsHelper::AssignmentSubscriptionError, 'Plagiarism review tool submission event service is missing endpoint')
      end
    end

  end
end

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
      '@id' => 'http://test.service.com/service#vnd.Canvas.SubmissionEvent',
      '@type' => 'RestService'
    }
  end
  let(:bad_submission_event_service) do
    {
      'format' => ['application/json'],
      'action' => ['POST'],
      '@id' => 'http://test.service.com/service#vnd.Canvas.SubmissionEvent',
      '@type' => 'RestService'
    }
  end
  let(:subscription_service){ class_double(Services::LiveEventsSubscriptionService).as_stubbed_const }

  before(:each) do
    course_with_teacher(active_all: true)
    allow(subscription_service).to receive_messages(create_tool_proxy_subscription: stub_response)
    allow(subscription_service).to receive_messages(available?: true)

    tool_proxy[:raw_data]['enabled_capability'] = %w(vnd.Canvas.webhooks.root_account.all)
    tool_proxy[:raw_data]['tool_profile'] = {'service_offered' => [submission_event_service]}
    tool_proxy.save!

    @assignment = @course.assignments.create!(name: 'test assignment')
  end

  describe '#create_subscription' do
    let(:subscription_helper) { Lti::AssignmentSubscriptionsHelper.new(tool_proxy, @assignment) }
    let(:event_types) do
       %w(submission_created
          plagiarism_resubmit
          submission_updated
          assignment_created
          assignment_updated).freeze
    end
    before(:each) do
      @assignment.tool_settings_tool = message_handler
      @assignment.save!
    end

    it 'creates a subscription and returns the id' do
      expect(subscription_helper.create_subscription).to eq 'test-id'
    end

    it "includes all required event types" do
      expect(subscription_helper.assignment_subscription(@assignment.id)[:EventTypes]).to match_array event_types

      Account.site_admin.enable_feature!(:system_and_user_generated_event_types)
      expect(subscription_helper.assignment_subscription(@assignment.id)[:SystemEventTypes]).to match_array event_types
      expect(subscription_helper.assignment_subscription(@assignment.id)[:UserEventTypes]).to match_array event_types
      Account.site_admin.disable_feature!(:system_and_user_generated_event_types)
    end

    it 'uses the live-event format' do
      expect(subscription_helper.assignment_subscription(@assignment.id)[:Format]).to eq 'live-event'
    end

    it 'uses the https transport type' do
      expect(subscription_helper.assignment_subscription(@assignment.id)[:TransportType]).to eq 'https'
    end

    it 'uses the transport metadata specified by the tool' do
      expect(subscription_helper.assignment_subscription(@assignment.id)[:TransportMetadata]).to eq({'Url' => submission_event_endpoint})
    end

    context 'bad subscriptions service configuration' do
      before(:each) do
        ss = class_double(Services::LiveEventsSubscriptionService).as_stubbed_const
        allow(ss).to receive_messages(create_tool_proxy_subscription: stub_bad_response)
        allow(ss).to receive_messages(available?: false)
      end

      it "raises 'AssignmentSubscriptionError' with error message if subscriptions service is not configured" do
        expect{subscription_helper.create_subscription}.to raise_exception(Lti::AssignmentSubscriptionsHelper::AssignmentSubscriptionError, 'Live events subscriptions service is not configured')
      end
    end

    context 'bad subscription request' do
      before(:each) do
        allow(subscription_service).to receive_messages(create_tool_proxy_subscription: stub_bad_response)
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

  describe '#destroy_description' do
    let(:subscription_helper){ Lti::AssignmentSubscriptionsHelper.new(tool_proxy) }

    before(:each) do
      allow(subscription_service).to receive_messages(destroy_tool_proxy_subscription: stub_response)
      @assignment.tool_settings_tool = message_handler
      @assignment.save!
    end

    it 'deletes a subscription' do
      lookup = AssignmentConfigurationToolLookup.where(assignment: @assignment).last
      expect(subscription_service).to receive(:destroy_tool_proxy_subscription).with(tool_proxy, lookup.subscription_id)
      subscription_helper.destroy_subscription(lookup.subscription_id)
    end

    it 'does not raise exception if subscription service is not configured' do
      allow(subscription_service).to receive_messages(available?: false)
      expect {subscription_helper.destroy_subscription('test')}.not_to raise_exception
    end

    it 'does not raise exception if delete fails' do
      allow(subscription_service).to receive_messages(create_tool_proxy_subscription: stub_bad_response)
      expect {subscription_helper.destroy_subscription('test')}.not_to raise_exception
    end
  end
end

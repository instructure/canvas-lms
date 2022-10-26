# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../../apis/lti/lti2_api_spec_helper"

describe Lti::PlagiarismSubscriptionsHelper do
  include_context "lti2_api_spec_helper"
  let(:test_subscription) { { "RootAccountId" => "1", "foo" => "bar" } }
  let(:stub_response) { double(code: 200, body: test_subscription.to_json, parsed_response: { "Id" => "test-id" }, ok?: true) }
  let(:stub_bad_response) { double(code: 200, body: test_subscription.to_json, parsed_response: { "Id" => "test-id" }, ok?: false) }
  let(:controller) { double(lti2_service_name: "vnd.Canvas.foo") }
  let(:submission_event_endpoint) { "test.com/submission" }
  let(:submission_event_service) do
    {
      "endpoint" => submission_event_endpoint,
      "format" => ["application/json"],
      "action" => ["POST"],
      "@id" => "http://test.service.com/service#vnd.Canvas.SubmissionEvent",
      "@type" => "RestService"
    }
  end
  let(:bad_submission_event_service) do
    {
      "format" => ["application/json"],
      "action" => ["POST"],
      "@id" => "http://test.service.com/service#vnd.Canvas.SubmissionEvent",
      "@type" => "RestService"
    }
  end
  let(:subscription_service) { class_double(Services::LiveEventsSubscriptionService).as_stubbed_const }

  before do
    course_with_teacher(active_all: true)
    allow(subscription_service).to receive_messages(create_tool_proxy_subscription: stub_response)
    allow(subscription_service).to receive_messages(available?: true)
    allow(subscription_service).to receive_messages(disabled?: false)

    tool_proxy[:raw_data]["enabled_capability"] = [Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2]
    tool_proxy[:raw_data]["tool_profile"] = { "service_offered" => [submission_event_service] }
    tool_proxy.save!
  end

  describe "#create_subscription" do
    let(:subscription_helper) { Lti::PlagiarismSubscriptionsHelper.new(tool_proxy) }
    let(:event_types) do
      %w[submission_created
         plagiarism_resubmit
         submission_updated
         assignment_created
         assignment_updated].freeze
    end

    it "creates a subscription and returns the id" do
      expect(subscription_helper.create_subscription).to eq "test-id"
    end

    it "includes all required event types" do
      expect(subscription_helper.plagiarism_subscription(tool_proxy, product_family)[:SystemEventTypes]).to match_array event_types
      expect(subscription_helper.plagiarism_subscription(tool_proxy, product_family)[:UserEventTypes]).to match_array event_types
    end

    it "uses the live-event format" do
      expect(subscription_helper.plagiarism_subscription(tool_proxy, product_family)[:Format]).to eq "live-event"
    end

    it "uses the https transport type" do
      expect(subscription_helper.plagiarism_subscription(tool_proxy, product_family)[:TransportType]).to eq "https"
    end

    it "uses the transport metadata specified by the tool" do
      expect(subscription_helper.plagiarism_subscription(tool_proxy, product_family)[:TransportMetadata]).to eq({ "Url" => submission_event_endpoint })
    end

    context "bad subscriptions service configuration" do
      before do
        @ss = class_double(Services::LiveEventsSubscriptionService).as_stubbed_const
        allow(@ss).to receive_messages(create_tool_proxy_subscription: stub_bad_response)
        allow(@ss).to receive_messages(available?: false)
      end

      it "does nothing if service is disabled" do
        expect(@ss).to receive_messages(disabled?: true)
        expect(subscription_helper.create_subscription).to be_nil
      end

      it "raises 'PlagiarismSubscriptionError' with error message if subscriptions service is not configured" do
        expect(@ss).to receive_messages(disabled?: false)
        expect { subscription_helper.create_subscription }.to raise_exception(Lti::PlagiarismSubscriptionsHelper::PlagiarismSubscriptionError, "Live events subscriptions service is not configured")
      end
    end

    context "bad subscription request" do
      before do
        allow(subscription_service).to receive_messages(create_tool_proxy_subscription: stub_bad_response)
      end

      it "raises 'PlagiarismSubscriptionError' if subscription service response is not ok" do
        expect { subscription_helper.create_subscription }.to raise_exception(Lti::PlagiarismSubscriptionsHelper::PlagiarismSubscriptionError)
      end

      it "raises 'PlagiarismSubscriptionError' with error message if service is missing" do
        tool_proxy[:raw_data]["tool_profile"] = { "service_offered" => [] }
        tool_proxy.save!
        subscription_helper = Lti::PlagiarismSubscriptionsHelper.new(Lti::ToolProxy.find(tool_proxy.id))
        expect { subscription_helper.create_subscription }.to raise_exception(Lti::PlagiarismSubscriptionsHelper::PlagiarismSubscriptionError, "Plagiarism review tool is missing submission event service")
      end

      it "raises 'PlagiarismSubscriptionError' with error message if service is missing endpoint" do
        tool_proxy[:raw_data]["tool_profile"] = { "service_offered" => [bad_submission_event_service] }
        tool_proxy.save!
        subscription_helper = Lti::PlagiarismSubscriptionsHelper.new(Lti::ToolProxy.find(tool_proxy.id))
        expect { subscription_helper.create_subscription }.to raise_exception(Lti::PlagiarismSubscriptionsHelper::PlagiarismSubscriptionError, "Plagiarism review tool submission event service is missing endpoint")
      end
    end
  end

  describe "#plagiarism_subscription" do
    let(:subscription_helper) { Lti::PlagiarismSubscriptionsHelper.new(tool_proxy) }

    it "has associated fields" do
      expect(subscription_helper.plagiarism_subscription(tool_proxy, tool_proxy.product_family)).to eq({
                                                                                                         "SystemEventTypes" => Lti::PlagiarismSubscriptionsHelper::EVENT_TYPES,
                                                                                                         "UserEventTypes" => Lti::PlagiarismSubscriptionsHelper::EVENT_TYPES,
                                                                                                         "ContextType" => "root_account",
                                                                                                         "ContextId" => tool_proxy.context.root_account.uuid,
                                                                                                         "Format" => "live-event",
                                                                                                         "TransportType" => "https",
                                                                                                         "TransportMetadata" => { "Url" => "test.com/submission" },
                                                                                                         "AssociatedIntegrationId" => tool_proxy.guid
                                                                                                       })
    end
  end

  describe "#destroy_subscription" do
    let(:subscription_helper) { Lti::PlagiarismSubscriptionsHelper.new(tool_proxy) }

    before do
      allow(subscription_service).to receive_messages(destroy_tool_proxy_subscription: stub_response)
    end

    it "deletes a subscription" do
      expect(subscription_service).to receive(:destroy_tool_proxy_subscription).with(tool_proxy, tool_proxy.subscription_id)
      subscription_helper.destroy_subscription(tool_proxy.subscription_id)
    end

    it "does not raise exception if subscription service is not configured" do
      allow(subscription_service).to receive_messages(available?: false)
      expect { subscription_helper.destroy_subscription("test") }.not_to raise_exception
    end

    it "does not raise exception if delete fails" do
      allow(subscription_service).to receive_messages(create_tool_proxy_subscription: stub_bad_response)
      expect { subscription_helper.destroy_subscription("test") }.not_to raise_exception
    end
  end
end

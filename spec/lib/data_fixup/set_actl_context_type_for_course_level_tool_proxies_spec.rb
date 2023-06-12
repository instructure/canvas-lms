# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../../lti2_spec_helper"

describe DataFixup::SetActlContextTypeForCourseLevelToolProxies do
  subject do
    lookup = AssignmentConfigurationToolLookup.create!(
      assignment:,
      tool_vendor_code: message_handler.tool_proxy.product_family.vendor_code,
      tool_product_code: message_handler.tool_proxy.product_family.product_code,
      tool_resource_type_code: message_handler.resource_handler.resource_type_code,
      tool_type: "Lti::MessageHandler",
      context_type: "Account"
    )
    described_class.run
    lookup.reload

    lookup.context_type
  end

  include_context "lti2_spec_helper"

  let(:assignment) { assignment_model(course:) }

  let(:subscription_service) { class_double(Services::LiveEventsSubscriptionService).as_stubbed_const }
  let(:test_id) { SecureRandom.uuid }
  let(:stub_response) { double(code: 200, parsed_response: { "Id" => test_id }, ok?: true) }

  before do
    allow(subscription_service).to receive_messages(available?: true)
    allow(subscription_service).to receive_messages(create_tool_proxy_subscription: stub_response)
    allow(subscription_service).to receive_messages(destroy_tool_proxy_subscription: stub_response)
  end

  context "when where is a course-level installation but no account-level installation" do
    let(:tool_proxy_context) { course }

    it "sets the ACTLs' context type to 'Course'" do
      expect(subject).to eq("Course")
    end
  end

  context "when where is a course-level installation and an account-level installation" do
    let(:tool_proxy_context) { course }

    before { create_tool_proxy(account) }

    it "does not update the ACTLs" do
      expect(subject).to eq("Account")
    end
  end

  context "when where is no course-level installation but an account-level installation" do
    it "does not update the ACTLs" do
      expect(subject).to eq("Account")
    end
  end
end

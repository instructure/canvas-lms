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

RSpec.shared_context "plagiarism_platform", shared_context: :metadata do
  include_context "lti2_spec_helper"

  let(:subscription_service) { class_double(Services::LiveEventsSubscriptionService).as_stubbed_const }
  let(:assignment) { assignment_model(course:) }
  let(:assignment_two) { assignment_model(course:) }

  def success_response
    double(code: 200, parsed_response: { "Id" => SecureRandom.uuid }, ok?: true)
  end

  before do
    allow(subscription_service).to receive_messages(available?: true, destroy_tool_proxy_subscription: success_response)
    allow(subscription_service).to receive(:create_tool_proxy_subscription).and_return(
      success_response,
      success_response,
      success_response,
      success_response
    )

    message_handler.update(capabilities: ["Canvas.placements.similarityDetection"])

    resource_handler.message_handlers << message_handler
    tool_proxy.resources << resource_handler
    tool_proxy.save!
  end
end

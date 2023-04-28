# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../api_spec_helper"

describe LtiApiController, type: :request do
  let(:lti_student) { user_model }
  let(:lti_course) { course_with_student({ user: lti_student, active_course: true }).course }
  let(:tool) do
    tool = lti_course.context_external_tools.new(
      name: "bob",
      consumer_key: "bob",
      shared_secret: "bob",
      tool_id: "some_tool",
      privacy_level: "public"
    )
    tool.url = "http://www.example.com/basic_lti"
    tool.resource_selection = {
      url: "http://#{HostUrl.default_host}/selection_test",
      selection_width: 400,
      selection_height: 400
    }
    tool.save!
    tool
  end

  let(:lti_assignment) do
    assignment = assignment_model(course: lti_course)
    tag = assignment.build_external_tool_tag(url: tool.url)
    tag.content_type = "ContextExternalTool"
    tag.content_id = tool.id
    tag.save!
    assignment
  end

  let(:request_body) do
    {
      "paperid" => 200_505_101,
      "outcomes_tool_placement_url" => "https://sandbox.turnitin.com/api/lti/1p0/outcome_tool_data/200505101?lang=en_us",
      "lis_result_sourcedid" => Lti::LtiOutboundAdapter.new(tool, lti_student, lti_course).encode_source_id(lti_assignment)
    }
  end

  before do
    allow(BasicLTI::Sourcedid).to receive(:encryption_secret) { "encryption-secret-5T14NjaTbcYjc4" }
    allow(BasicLTI::Sourcedid).to receive(:signing_secret) { "signing-secret-vp04BNqApwdwUYPUI" }
  end

  def lti_api_call(method, path, body = nil)
    consumer = OAuth::Consumer.new(tool.consumer_key, tool.shared_secret, site: "https://www.example.com", signature_method: "HMAC-SHA1")
    req = consumer.create_signed_request(:post, path, nil, { scheme: "header", timestamp: Time.now.to_i, nonce: SecureRandom.hex(32) }, body)
    content_type = body.is_a?(Hash) ? "application/x-www-form-urlencoded" : "application/json"
    __send__(method,
             "https://www.example.com#{req.path}",
             params: req.body,
             headers: { "CONTENT_TYPE" => content_type, "HTTP_AUTHORIZATION" => req["Authorization"] })
  end

  describe "turnitin_outcomes_placement" do
    let(:request_path) { "/api/lti/v1/turnitin/outcomes_placement/#{tool.id}" }

    it "accepts valid oauth request" do
      lti_api_call(:post, request_path, request_body.to_json)
      expect(request.headers["Authorization"]).to include "oauth_body_hash"
      expect(response).to be_successful
    end

    it "disables the turnitin plugin for the assignment" do
      lti_assignment.turnitin_enabled = true
      lti_assignment.save!
      lti_api_call(:post, request_path, request_body.to_json)
      lti_assignment.reload
      expect(lti_assignment.turnitin_enabled).to be_falsey
    end
  end
end

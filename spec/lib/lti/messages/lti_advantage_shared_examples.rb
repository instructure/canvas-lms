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

RSpec.shared_context "lti_advantage_shared_examples" do
  include_context "key_storage_helper"

  let(:return_url) { "http://www.platform.com/return_url" }
  let(:opts) { { resource_type: "course_navigation" } }
  let(:lti_assignment) { Lti::LtiAssignmentCreator.new(assignment).convert }
  let(:deep_linking_return_url) { "http://www.test.cop/success" }
  let(:controller) do
    controller = double("controller")
    allow(controller).to receive_messages(request:, polymorphic_url: deep_linking_return_url)
    allow(controller).to receive(:params)
    controller
  end
  # All this setup just so we can stub out controller.*_url methods
  let(:request) do
    request = double("request")
    allow(request).to receive_messages(url: "https://localhost", host: "/my/url", scheme: "https")
    request
  end
  let(:expander_opts) do
    {
      current_user: user,
      tool:,
      assignment:,
      collaboration:
    }
  end
  let(:expander) do
    Lti::VariableExpander.new(
      course.root_account,
      course,
      controller,
      expander_opts
    )
  end
  let(:collaboration) { nil }
  let(:assignment) do
    assignment_model(
      course:,
      submission_types: "external_tool",
      external_tool_tag_attributes: { content: tool, url: tool.url }
    )
  end
  let_once(:user) { user_model(email: "banana@test.com") }
  let_once(:course) do
    course_with_student
    @course
  end

  let(:registration) do
    lti_registration_with_tool(
      account: course.root_account,
      developer_key_params: { scopes: developer_key_scopes },
      configuration_params: {
        target_link_uri: "http://www.example.com/basic_lti",
        oidc_initiation_url: "http://www.example.com/basic_lti",
        domain: "www.example.com",
        placements: [
          {
            placement: "course_navigation",
            message_type: "LtiResourceLinkRequest",
            selection_width: 500,
            selection_height: 400,
            custom_fields: {
              has_expansion: "$User.id",
              no_expansion: "foo"
            }
          }
        ]
      }
    )
  end
  let(:tool) { registration.deployments.first }
  let(:developer_key_scopes) { [] }

  shared_examples_for "lti 1.3 message initialization" do
    it "adds public claims if the tool is public" do
      tool.update!(workflow_state: "public")
      expect(jws[:post_payload]["picture"]).to eq user.avatar_url
    end

    it "does not add public claims if the tool is not public" do
      tool.update!(workflow_state: "private")
      expect(jws[:post_payload]).not_to include "picture"
    end

    it "adds include email claims if the tool is include email" do
      tool.update!(workflow_state: "email_only")
      expect(jws[:post_payload]["email"]).to eq user.email
    end

    it "does not add include email claims if the tool is not include email" do
      user.update!(email: "banana@test.com")
      tool.update!(workflow_state: "private")
      expect(jws[:post_payload]).not_to include "email"
    end

    it "adds include name claims if the tool is include name" do
      tool.update!(workflow_state: "name_only")
      expect(jws[:post_payload]["name"]).to eq user.name
    end

    it "does not add include name claims if the tool is not include name" do
      tool.update!(workflow_state: "private")
      expect(jws[:post_payload]).not_to include "name"
    end

    it "adds private claims" do
      expect(jws[:post_payload]["locale"]).to eq "en"
    end

    it "adds security claims" do
      expected_sub = user.lti_id
      expect(jws[:post_payload]["sub"]).to eq expected_sub
    end
  end
end

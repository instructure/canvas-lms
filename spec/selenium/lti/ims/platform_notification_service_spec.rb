# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "page_objects/mock_lti_tool_ui"
require_relative "../../assignments/page_objects/assignment_create_edit_page"

describe "Platform Notification Service" do
  include_context "in-process server selenium tests"

  let(:course) { course_model }
  let(:base_url) { "http://#{HostUrl.default_host}/test/mock_lti" }
  let(:registration) do
    configuration_params = {
      scopes: ["https://purl.imsglobal.org/spec/lti/scope/noticehandlers"],
      redirect_uris: ["#{base_url}/ui"],
      placements: [{
        placement: "ActivityAssetProcessor",
        message_type: "LtiDeepLinkingRequest",
      }],
      oidc_initiation_url: "#{base_url}/login",
      public_jwk_url: "#{base_url}/jwks",
      domain: HostUrl.default_host,
    }

    lti_registration_with_tool(account: course.account, configuration_params:)
  end

  before do
    # With an asset processor tool installed in a course
    teacher = user_model
    account_admin_user(name: "A User", account: course.account)
    course.enroll_teacher(teacher, enrollment_state: "active")
    user_session(teacher)

    Lti::UpdateRegistrationService.call(
      id: registration.id,
      account: course.account,
      updated_by: teacher,
      binding_params: { workflow_state: "on" }
    )

    key = OpenSSL::PKey::RSA.new 2048
    allow(Lti::KeyStorage).to receive(:present_key).and_return(key)

    allow_any_instance_of(Lti::IMS::NoticeHandlersController).to receive(:verify_access_token).and_return(true)
    allow_any_instance_of(Lti::IMS::NoticeHandlersController).to receive(:developer_key).and_return(registration.developer_key)
    allow_any_instance_of(Lti::IMS::NoticeHandlersController).to receive(:verify_access_scope).and_return(true)
  end

  it "registers a Notice Handler" do
    # Visit the new assignment page
    get("/courses/#{course.id}/assignments/new")

    # Set assignment type to text submission
    AssignmentCreateEditPage.select_text_entry_submission_type

    # Click the asset processor button
    scroll_into_view(AssignmentCreateEditPage.add_asset_processor_button)
    AssignmentCreateEditPage.add_asset_processor_button.click
    f("[data-testid='asset-processor-card']").click

    # Expect the iframe modal to have loaded
    expect(f("[role='dialog'] h2").text).to eq("Add A Document Processing App")

    in_frame(AssignmentCreateEditPage.lti_tool_iframe) do
      MockLtiToolUi.notification_button.click
    end

    # After clicking the mock tool's notification_button, this LTI registration
    # should have an lti_notice_handler created on it.
    keep_trying_until do
      tool_deployment = registration.deployments.first
      expect(tool_deployment.lti_notice_handlers.first.url)
        .to eq("#{base_url}/subscription_handler")
    end
  end
end

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

describe "Asset Processor" do
  include_context "in-process server selenium tests"

  # Cache expensive RSA key generation across all tests
  let(:rsa_key) { OpenSSL::PKey::RSA.new 2048 }

  let(:course) { course_model }
  let(:base_url) { "http://#{HostUrl.default_host}/test/mock_lti" }
  let(:student) { student_in_course(course:, active_all: true).user }
  let(:teacher) { teacher_in_course(course:, active_all: true).user }
  let(:assignment) { assignment_model(course:, submission_types: "online_text_entry", workflow_state: "published") }

  let(:registration) do
    configuration_params = {
      scopes: [
        "https://purl.imsglobal.org/spec/lti/scope/noticehandlers",
        "https://purl.imsglobal.org/spec/lti/scope/asset.readonly",
        "https://purl.imsglobal.org/spec/lti/scope/report",
        "https://purl.imsglobal.org/spec/lti/scope/eula/user"
      ],
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

  let(:tool) do
    registration.deployments.first.tap do |t|
      t.settings["message_settings"] = [
        {
          "type" => "LtiEulaRequest",
          "enabled" => true,
          "target_link_uri" => "#{base_url}/ui"
        }
      ]
      t.save!
    end
  end

  before do
    course.offer!
    course.root_account.enable_feature!(:lti_asset_processor)

    Lti::UpdateRegistrationService.call(
      id: registration.id,
      account: course.account,
      updated_by: teacher,
      binding_params: { workflow_state: "on" }
    )

    allow(Lti::KeyStorage).to receive(:present_key).and_return(rsa_key)

    allow_any_instance_of(Lti::IMS::AssetProcessorEulaController)
      .to receive(:verify_access_token).and_return(true)
    allow_any_instance_of(Lti::IMS::AssetProcessorEulaController)
      .to receive(:developer_key).and_return(registration.developer_key)
    allow_any_instance_of(Lti::IMS::AssetProcessorEulaController)
      .to receive(:verify_access_scope).and_return(true)
  end

  describe "Student EULA Acceptance" do
    before do
      student.update!(root_account_ids: [course.root_account.id])
      assignment.lti_asset_processors.create!(
        context_external_tool: tool,
        workflow_state: "active"
      )
    end

    it "student accepts EULA when viewing assignment for the first time", skip: "INTEROP-9987 2025-01-29" do
      user_session(student)
      get("/courses/#{course.id}/assignments/#{assignment.id}")
      wait_for_ajaximations

      expect(f("[role='dialog']")).to be_displayed

      # Switch to the EULA iframe and interact with the tool
      in_frame(f("iframe[title*='EULA']"), "#eula-accept-btn") do
        wait_for_ajaximations
        button = MockLtiToolUi.eula_accept_button
        expect(button).to be_displayed
        button.click
      end

      # After accepting, verify the EULA acceptance is recorded
      keep_trying_until do
        student.reload
        acceptance = student.lti_asset_processor_eula_acceptances.active.find_by(
          context_external_tool_id: tool.id
        )
        expect(acceptance).to be_present
        expect(acceptance.accepted).to be true
      end
    end

    it "student not required to accept EULA when previously accepted" do
      student.lti_asset_processor_eula_acceptances.create!(
        context_external_tool_id: tool.id,
        accepted: true,
        timestamp: Time.zone.now,
        workflow_state: "active"
      )
      user_session(student)
      get("/courses/#{course.id}/assignments/#{assignment.id}")
      wait_for_ajaximations

      expect(f("body")).not_to contain_css("[role='dialog']")
      expect(f("h1")).to include_text(assignment.title)
    end
  end

  describe "Teacher SpeedGrader Asset Processor Reports" do
    let(:asset_processor) do
      assignment.lti_asset_processors.create!(
        context_external_tool: tool,
        workflow_state: "active"
      )
    end

    let(:submission) { assignment.submit_homework(student, submission_type: "online_text_entry", body: "Test submission") }

    before do
      allow_any_instance_of(Lti::IMS::AssetProcessorController)
        .to receive(:verify_access_token).and_return(true)
      allow_any_instance_of(Lti::IMS::AssetProcessorController)
        .to receive(:developer_key).and_return(registration.developer_key)
      allow_any_instance_of(Lti::IMS::AssetProcessorController)
        .to receive(:verify_access_scope).and_return(true)
    end

    it "teacher views AP summary from speedgrader and requests report" do
      # Create a processed originality report for the submission
      asset = lti_asset_model(submission:)
      processed_lti_asset_report_model(
        asset:,
        asset_processor:,
        report_type: "originality",
        title: "Turnitin Originality Report",
        comment: "High similarity detected",
        result: "83/100",
        indication_color: "#EC0000",
        indication_alt: "High percentage of matched text",
        priority: 5,
        processing_progress: "Processed"
      )

      user_session(teacher)
      get("/courses/#{course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}")
      wait_for_ajaximations

      expect(f("#speed_grader_lti_asset_reports_mount_point")).to be_displayed
      expect(f("#speed_grader_lti_asset_reports_mount_point")).to include_text("Turnitin Originality Report")
      expect(f("#speed_grader_lti_asset_reports_mount_point")).to include_text("83/100")

      button = f("#asset-processor-view-report-button")
      expect(button).to be_displayed
      button.click
    end
  end
end

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
#

describe SupportHelpers::AssetProcessorController do
  describe "require_site_admin" do
    it "redirects to root url if current user is not a site admin" do
      account_admin_user
      user_session(@user)
      get :submission_details, params: { assignment_id: 1, student_id: 1 }
      assert_unauthorized
    end

    it "redirects to login if current user is not logged in" do
      get :submission_details, params: { assignment_id: 1, student_id: 1 }
      assert_unauthorized
    end

    it "renders 200 if current user is a site admin" do
      site_admin_user
      user_session(@user)

      course = course_with_student(active_all: true).course
      assignment = assignment_model(course:)
      submission_model(assignment:, user: @student)

      get :submission_details, params: { assignment_id: assignment.id, student_id: @student.id }
      expect(response).to be_successful
    end
  end

  describe "submission_details" do
    before do
      site_admin_user
      user_session(@user)

      @course = course_with_student(active_all: true).course
      @assignment = assignment_model(course: @course)
      @student = @course.student_enrollments.first.user
      @submission = submission_model(assignment: @assignment, user: @student)

      # Create a tool with an asset processor
      @tool = external_tool_1_3_model(context: @course, placements: ["ActivityAssetProcessor"])
      @asset_processor = lti_asset_processor_model(assignment: @assignment, tool: @tool)

      # Create an attachment and asset
      @attachment = attachment_model(context: @student)
      @asset = lti_asset_model(submission: @submission, attachment: @attachment)

      # Create an asset report
      @asset_report = lti_asset_report_model(
        asset: @asset,
        asset_processor: @asset_processor,
        processing_progress: "Processed",
        report_type: "originality",
        result: "85%"
      )
    end

    it "returns 404 if submission is not found" do
      get :submission_details, params: { assignment_id: @assignment.id, student_id: 999_999 }
      expect(response).to have_http_status :not_found
      json = response.parsed_body
      expect(json["error"]).to eq "Submission not found"
    end

    it "returns submission details in json format" do
      get :submission_details, params: { assignment_id: @assignment.id, student_id: @student.id }

      expect(response).to have_http_status :ok
      json = response.parsed_body

      # Check the structure of the response
      expect(json).to have_key("assignment")
      expect(json).to have_key("submission")
      expect(json).to have_key("asset_processors")
      expect(json).to have_key("context_external_tools")
      expect(json).to have_key("notice_handlers")
      expect(json).to have_key("assets")
      expect(json).to have_key("asset_reports")

      # Check specific data
      expect(json["assignment"]["id"]).to eq @assignment.id
      expect(json["submission"]["id"]).to eq @submission.id
      expect(json["asset_processors"].first["id"]).to eq @asset_processor.id
      expect(json["context_external_tools"].first["id"]).to eq @tool.id
      expect(json["assets"].first["id"]).to eq @asset.id
      expect(json["assets"].first["attachment_id"]).to eq @attachment.id
      expect(json["asset_reports"].first["id"]).to eq @asset_report.id
      expect(json["asset_reports"].first["report_type"]).to eq "originality"
    end

    it "returns DOT graph representation when graph=true parameter is provided" do
      get :submission_details, params: { assignment_id: @assignment.id, student_id: @student.id, graph: "true" }

      expect(response).to have_http_status :ok
      expect(response.content_type).to include("text/plain")

      # Check for basic graph elements
      dot_content = response.body
      expect(dot_content).to include("digraph AssetProcessorGraph {")
      expect(dot_content).to include("Assignment_#{@assignment.id}")
      expect(dot_content).to include("Submission_#{@submission.id}")
      expect(dot_content).to include("Tool_#{@tool.id}")
      expect(dot_content).to include("AssetProcessor_#{@asset_processor.id}")
      expect(dot_content).to include("Asset_#{@asset.id}")
      expect(dot_content).to include("AssetReport_#{@asset_report.id}")

      # Check for edges (relationships)
      expect(dot_content).to include("Assignment_#{@assignment.id} -> Submission_#{@submission.id};")
      expect(dot_content).to include("Tool_#{@tool.id} -> AssetProcessor_#{@asset_processor.id};")
      expect(dot_content).to include("Submission_#{@submission.id} -> Asset_#{@asset.id};")
      expect(dot_content).to include("Asset_#{@asset.id} -> AssetReport_#{@asset_report.id};")
      expect(dot_content).to include("AssetProcessor_#{@asset_processor.id} -> AssetReport_#{@asset_report.id};")
    end
  end

  describe "bulk_resubmit_discussion" do
    before do
      site_admin_user
      user_session(@user)

      @course = course_with_student(active_all: true).course
      @student = @course.student_enrollments.first.user

      # Create a graded discussion topic
      @assignment = assignment_model(course: @course, submission_types: "discussion_topic")
      @discussion_topic = @assignment.discussion_topic

      # Create a tool with an asset processor for discussions
      @tool = external_tool_1_3_model(context: @course, placements: ["ActivityAssetProcessorContribution"])
    end

    it "returns 400 if neither discussion_topic_id nor course_id is provided" do
      post :bulk_resubmit_discussion, params: {}
      expect(response).to have_http_status :bad_request
      json = response.parsed_body
      expect(json["error"]).to eq "discussion_topic_id or course_id is required"
    end

    it "accepts discussion_topic_id and initiates fixer" do
      expect_any_instance_of(SupportHelpers::AssetProcessorDiscussionNoticeResubmission).to receive(:monitor_and_fix)

      post :bulk_resubmit_discussion, params: { discussion_topic_id: @discussion_topic.id }
      expect(response).to have_http_status :ok
    end

    it "accepts course_id and initiates fixer" do
      expect_any_instance_of(SupportHelpers::AssetProcessorDiscussionNoticeResubmission).to receive(:monitor_and_fix)

      post :bulk_resubmit_discussion, params: { course_id: @course.id }
      expect(response).to have_http_status :ok
    end

    it "accepts optional tool_id parameter" do
      expect_any_instance_of(SupportHelpers::AssetProcessorDiscussionNoticeResubmission).to receive(:monitor_and_fix)

      post :bulk_resubmit_discussion, params: { discussion_topic_id: @discussion_topic.id, tool_id: @tool.id }
      expect(response).to have_http_status :ok
    end
  end
end

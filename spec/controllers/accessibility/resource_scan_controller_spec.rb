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

describe Accessibility::ResourceScanController do
  let(:course) { course_model }

  before do
    allow_any_instance_of(described_class).to receive(:require_user).and_return(true)
    allow_any_instance_of(described_class).to receive(:check_authorized_action).and_return(true)

    # Create three scans with differing attributes so every sort field has
    # distinguishable values.
    accessibility_resource_scan_model(
      course:,
      context: assignment_model(course:),
      workflow_state: "queued",
      resource_name: "Queued Resource",
      resource_workflow_state: :published,
      issue_count: 1,
      resource_updated_at: 3.days.ago
    )

    accessibility_resource_scan_model(
      course:,
      context: attachment_model(course:),
      workflow_state: "in_progress",
      resource_name: "In Progress Resource",
      resource_workflow_state: :unpublished,
      issue_count: 2,
      resource_updated_at: 2.days.ago.beginning_of_day
    )

    accessibility_resource_scan_model(
      course:,
      context: wiki_page_model(course:),
      workflow_state: "completed",
      resource_name: "Completed Resource",
      resource_workflow_state: :published,
      issue_count: 3,
      resource_updated_at: 3.days.ago
    )
  end

  context "when a11y_checker feature flag disabled" do
    it "renders forbidden" do
      allow_any_instance_of(described_class).to receive(:check_authorized_action).and_call_original
      allow(course).to receive(:a11y_checker_enabled?).and_return(false)

      expect(controller).to receive(:render).with(status: :forbidden)
      controller.send(:check_authorized_action)
    end
  end

  describe "GET #index" do
    %w[resource_name resource_type resource_workflow_state resource_updated_at issue_count].each do |sort_param|
      it "sorts by #{sort_param} ascending and descending" do
        # Ascending order
        get :index, params: { course_id: course.id, sort: sort_param, direction: "asc" }, format: :json
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json.length).to eq(3)

        asc_values = json.pluck(sort_param)

        # Descending order
        get :index, params: { course_id: course.id, sort: sort_param, direction: "desc" }, format: :json
        expect(response).to have_http_status(:ok)
        desc_json = response.parsed_body
        expect(desc_json.length).to eq(3)

        desc_values = desc_json.pluck(sort_param)

        expect(desc_values).to eq(asc_values.reverse)
      end
    end

    it "only includes issue_count and issues for completed scans" do
      get :index, params: { course_id: course.id }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body

      queued_json = json.find { |scan| scan["resource_name"] == "Queued Resource" }
      expect(queued_json).not_to have_key("issue_count")
      expect(queued_json).not_to have_key("issues")

      in_progress_json = json.find { |scan| scan["resource_name"] == "In Progress Resource" }
      expect(in_progress_json).not_to have_key("issue_count")
      expect(in_progress_json).not_to have_key("issues")

      completed_json = json.find { |scan| scan["resource_name"] == "Completed Resource" }
      expect(completed_json["issue_count"]).to eq(3)
      expect(completed_json).to have_key("issues")
    end

    context "with issues" do
      let(:wiki_page) do
        wiki_page_model(course:)
      end
      let(:scan_with_issues) do
        accessibility_resource_scan_model(
          course:,
          context: wiki_page,
          workflow_state: "completed",
          resource_updated_at: "2025-07-19T02:18:00Z",
          resource_name: "Tutorial",
          resource_workflow_state: "published",
          issue_count: 1
        )
      end
      let!(:issue) do
        accessibility_issue_model(
          course:,
          accessibility_resource_scan: scan_with_issues,
          rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
          node_path: "./div/h1",
          metadata: {
            element: "h1",
            form: {
              type: "radio_input_group"
            },
          }
        )
      end

      it "sets the issue attributes" do
        get :index, params: { course_id: course.id }, format: :json
        expect(response).to have_http_status(:ok)

        json = response.parsed_body
        scan_with_issues_json = json.find { |scan| scan["id"] == scan_with_issues.id }

        expected_json = {
          "id" => scan_with_issues.id,
          "resource_id" => scan_with_issues.wiki_page_id,
          "resource_type" => "WikiPage",
          "resource_name" => "Tutorial",
          "resource_workflow_state" => "published",
          "resource_updated_at" => "2025-07-19T02:18:00Z",
          "resource_url" => "/courses/#{course.id}/pages/#{wiki_page.id}",
          "workflow_state" => "completed",
          "error_message" => "",
          "issue_count" => 1,
          "issues" => [
            {
              "id" => issue.id,
              "rule_id" => "headings-start-at-h2",
              "element" => "h1",
              "display_name" => "Heading levels should start at level 2",
              "message" => "Heading levels in your content should start at level 2 (H2), because there's already a Heading 1 on the page it's displayed on.",
              "why" => "Sighted users scan web pages quickly by looking for large or bolded headings. Similarly, screen reader users rely on properly structured headings to scan the content and jump directly to key sections. Using correct heading levels in a logical (like H2, H3, etc.) ensures your course is clear, organized, and accessible to everyone. Each page on Canvas already has a main title (H1), so your content should start with an H2 to keep the structure clear.",
              "path" => "./div/h1",
              "issue_url" => "https://www.w3.org/WAI/tutorials/page-structure/headings/",
              "form" => { "type" => "radio_input_group" }
            }
          ]
        }

        expect(scan_with_issues_json).to eq(expected_json)
      end

      context "with resolved or dismissed issues" do
        let!(:resolved_issue) do
          accessibility_issue_model(
            course:,
            context: wiki_page,
            accessibility_resource_scan: scan_with_issues,
            rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
            workflow_state: "resolved"
          )
        end
        let!(:dismissed_issue) do
          accessibility_issue_model(
            course:,
            context: wiki_page,
            accessibility_resource_scan: scan_with_issues,
            rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
            workflow_state: "dismissed"
          )
        end

        it "does not retrieve resolved or dismissed issues" do
          get :index, params: { course_id: course.id }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          scan_with_issues_json = json.find { |scan| scan["id"] == scan_with_issues.id }
          issue_ids = scan_with_issues_json["issues"].pluck("id")

          expect(issue_ids).not_to include(resolved_issue.id)
          expect(issue_ids).not_to include(dismissed_issue.id)
        end
      end

      context "with filters" do
        it "filters by rule types" do
          get :index, params: { course_id: course.id, filters: { ruleTypes: ["headings-start-at-h2"] } }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(1)
          expect(json.first["id"]).to eq(scan_with_issues.id)
        end

        it "filters by resource types" do
          get :index, params: { course_id: course.id, filters: { artifactTypes: ["assignment"] } }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(1)
          expect(json.all? { |scan| scan["resource_type"] == "Assignment" }).to be true
        end

        it "filters by workflow states" do
          get :index, params: { course_id: course.id, filters: { workflowStates: ["published"] } }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(3)
          expect(json.all? { |scan| scan["resource_workflow_state"] == "published" }).to be true
        end

        it "filters by date range" do
          get :index, params: { course_id: course.id, filters: { fromDate: 2.days.ago.beginning_of_day, toDate: 1.day.ago } }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(1)
          expect(json.first["resource_name"]).to eq("In Progress Resource")
        end

        it "applies multiple filters together" do
          get :index, params: { course_id: course.id, filters: { artifactTypes: ["wiki_page"], workflowStates: ["published"] } }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(2)
          expect(json.first["resource_name"]).to eq("Completed Resource")
        end

        it "returns all scans if filters are empty" do
          get :index, params: { course_id: course.id, filters: {} }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(4)
        end

        it "filters by search term" do
          get :index, params: { course_id: course.id, search: "Tut" }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(1)
          expect(json.first["resource_name"]).to eq("Tutorial")
        end

        it "filters by search term case insensitively" do
          get :index, params: { course_id: course.id, search: "tutorial" }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json.length).to eq(1)
          expect(json.first["resource_name"]).to eq("Tutorial")
        end

        it "returns no results for non-matching search term" do
          get :index, params: { course_id: course.id, search: "Nonexistent" }, format: :json
          expect(response).to have_http_status(:ok)

          json = response.parsed_body
          expect(json).to be_empty
        end
      end
    end
  end

  describe "GET #poll" do
    let(:queued_scan) do
      accessibility_resource_scan_model(
        course:,
        context: assignment_model(course:),
        workflow_state: "queued",
        resource_name: "Queued Scan"
      )
    end

    let(:in_progress_scan) do
      accessibility_resource_scan_model(
        course:,
        context: wiki_page_model(course:),
        workflow_state: "in_progress",
        resource_name: "In Progress Scan"
      )
    end

    let(:completed_scan) do
      accessibility_resource_scan_model(
        course:,
        context: wiki_page_model(course:),
        workflow_state: "completed",
        resource_name: "Completed Scan",
        issue_count: 2
      )
    end

    let(:failed_scan) do
      accessibility_resource_scan_model(
        course:,
        context: attachment_model(course:),
        workflow_state: "failed",
        resource_name: "Failed Scan",
        error_message: "Scan failed"
      )
    end

    it "returns empty array when no scan_ids provided" do
      get :poll, params: { course_id: course.id }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"]).to eq([])
    end

    it "returns empty array when scan_ids is empty string" do
      get :poll, params: { course_id: course.id, scan_ids: "" }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"]).to eq([])
    end

    it "returns requested scans by scan_ids" do
      scan1_id = queued_scan.id
      scan2_id = in_progress_scan.id

      get :poll, params: { course_id: course.id, scan_ids: "#{scan1_id},#{scan2_id}" }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"].length).to eq(2)

      scan_ids = json["scans"].pluck("id")
      expect(scan_ids).to contain_exactly(scan1_id, scan2_id)
    end

    it "only includes scans from the specified course" do
      other_course = course_model
      other_scan = accessibility_resource_scan_model(
        course: other_course,
        context: assignment_model(course: other_course),
        workflow_state: "queued"
      )

      scan_id = queued_scan.id

      get :poll, params: { course_id: course.id, scan_ids: "#{scan_id},#{other_scan.id}" }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"].length).to eq(1)
      expect(json["scans"][0]["id"]).to eq(scan_id)
    end

    it "does not include issue_count and issues for queued scans" do
      scan_id = queued_scan.id

      get :poll, params: { course_id: course.id, scan_ids: scan_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      scan_json = json["scans"][0]

      expect(scan_json).not_to have_key("issue_count")
      expect(scan_json).not_to have_key("issues")
    end

    it "does not include issue_count and issues for in_progress scans" do
      scan_id = in_progress_scan.id

      get :poll, params: { course_id: course.id, scan_ids: scan_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      scan_json = json["scans"][0]

      expect(scan_json).not_to have_key("issue_count")
      expect(scan_json).not_to have_key("issues")
    end

    it "includes issue_count and issues for completed scans" do
      scan_id = completed_scan.id
      accessibility_issue_model(
        course:,
        accessibility_resource_scan: completed_scan,
        rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id
      )

      get :poll, params: { course_id: course.id, scan_ids: scan_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      scan_json = json["scans"][0]

      expect(scan_json["issue_count"]).to eq(2)
      expect(scan_json).to have_key("issues")
      expect(scan_json["issues"]).to be_an(Array)
    end

    it "does not include issue_count and issues for failed scans" do
      scan_id = failed_scan.id

      get :poll, params: { course_id: course.id, scan_ids: scan_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      scan_json = json["scans"][0]

      expect(scan_json).not_to have_key("issue_count")
      expect(scan_json).not_to have_key("issues")
      expect(scan_json["error_message"]).to eq("Scan failed")
    end

    it "handles mixed scan states correctly" do
      queued_id = queued_scan.id
      in_progress_id = in_progress_scan.id
      completed_id = completed_scan.id
      failed_id = failed_scan.id

      scan_ids = "#{queued_id},#{in_progress_id},#{completed_id},#{failed_id}"

      get :poll, params: { course_id: course.id, scan_ids: }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"].length).to eq(4)

      queued_json = json["scans"].find { |s| s["id"] == queued_id }
      expect(queued_json).not_to have_key("issue_count")

      in_progress_json = json["scans"].find { |s| s["id"] == in_progress_id }
      expect(in_progress_json).not_to have_key("issue_count")

      completed_json = json["scans"].find { |s| s["id"] == completed_id }
      expect(completed_json["issue_count"]).to eq(2)
      expect(completed_json).to have_key("issues")

      failed_json = json["scans"].find { |s| s["id"] == failed_id }
      expect(failed_json).not_to have_key("issue_count")
      expect(failed_json).not_to have_key("issues")
      expect(failed_json["error_message"]).to eq("Scan failed")
    end

    it "returns correct JSON structure for each scan" do
      scan_id = completed_scan.id

      get :poll, params: { course_id: course.id, scan_ids: scan_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      scan_json = json["scans"][0]

      expect(scan_json).to have_key("id")
      expect(scan_json).to have_key("resource_id")
      expect(scan_json).to have_key("resource_type")
      expect(scan_json).to have_key("resource_name")
      expect(scan_json).to have_key("resource_workflow_state")
      expect(scan_json).to have_key("resource_updated_at")
      expect(scan_json).to have_key("resource_url")
      expect(scan_json).to have_key("workflow_state")
      expect(scan_json).to have_key("error_message")
    end

    it "handles non-existent scan IDs gracefully" do
      non_existent_id = 999_999

      get :poll, params: { course_id: course.id, scan_ids: non_existent_id.to_s }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"]).to be_empty
    end

    it "accepts up to the maximum number of scan IDs" do
      # Create 10 scans (the default limit)
      scans = (1..10).map do |_i|
        accessibility_resource_scan_model(
          course:,
          context: assignment_model(course:),
          workflow_state: "queued"
        )
      end

      scan_ids = scans.map(&:id).join(",")

      get :poll, params: { course_id: course.id, scan_ids: }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json["scans"].length).to eq(10)
    end

    it "rejects more than the maximum number of scan IDs" do
      # Create 11 scans (exceeds the default limit of 10)
      scans = (1..11).map do |_i|
        accessibility_resource_scan_model(
          course:,
          context: assignment_model(course:),
          workflow_state: "queued"
        )
      end

      scan_ids = scans.map(&:id).join(",")

      get :poll, params: { course_id: course.id, scan_ids: }, format: :json
      expect(response).to have_http_status(:bad_request)

      json = response.parsed_body
      expect(json["error"]).to include("Too many scan IDs")
      expect(json["error"]).to include("Maximum allowed: 10")
    end

    it "respects custom limit from settings" do
      Setting.set("accessibility_resource_scan_poll_max_ids", "5")

      # Create 6 scans (exceeds the custom limit of 5)
      scans = (1..6).map do |_i|
        accessibility_resource_scan_model(
          course:,
          context: assignment_model(course:),
          workflow_state: "queued"
        )
      end

      scan_ids = scans.map(&:id).join(",")

      get :poll, params: { course_id: course.id, scan_ids: }, format: :json
      expect(response).to have_http_status(:bad_request)

      json = response.parsed_body
      expect(json["error"]).to include("Maximum allowed: 5")

      # Clean up setting
      Setting.remove("accessibility_resource_scan_poll_max_ids")
    end
  end
end

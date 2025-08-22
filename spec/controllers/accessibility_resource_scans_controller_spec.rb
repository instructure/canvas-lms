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

describe AccessibilityResourceScansController do
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

    it "sets issue_count if scan complete" do
      get :index, params: { course_id: course.id }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body

      queued_json = json.find { |scan| scan["resource_name"] == "Queued Resource" }
      expect(queued_json["issue_count"]).to eq(0)

      in_progress_json = json.find { |scan| scan["resource_name"] == "In Progress Resource" }
      expect(in_progress_json["issue_count"]).to eq(0)

      completed_json = json.find { |scan| scan["resource_name"] == "Completed Resource" }
      expect(completed_json["issue_count"]).to eq(3)
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
      end
    end
  end
end

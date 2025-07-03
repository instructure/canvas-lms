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

require "spec_helper"

describe AccessibilityResourceScansController do
  let(:course) { course_model }

  before do
    # Stub authentication/authorization helpers expected by ApplicationController
    allow_any_instance_of(described_class).to receive(:require_context).and_return(true)
    allow_any_instance_of(described_class).to receive(:require_user).and_return(true)
    allow_any_instance_of(described_class).to receive(:authorized_action).and_return(true)
    allow_any_instance_of(described_class).to receive(:tab_enabled?)
      .with(Course::TAB_ACCESSIBILITY).and_return(true)
    allow_any_instance_of(described_class).to receive(:t).and_return("Accessibility")
    allow_any_instance_of(described_class).to receive(:add_crumb)

    # Provide @context so the controller can scope the query
    controller.instance_variable_set(:@context, course)

    # Create three scans with differing attributes so every sort field has
    # distinguishable values.
    @scan_assignment = accessibility_resource_scan_model(
      course:,
      assignment: assignment_model(course:),
      workflow_state: "queued",
      resource_name: "Course",
      resource_workflow_state: :published,
      issue_count: 1,
      resource_updated_at: 2.days.ago
    )

    @scan_attachment = accessibility_resource_scan_model(
      course:,
      attachment: attachment_model(course:),
      workflow_state: "queued",
      resource_name: "PDF",
      resource_workflow_state: :unpublished,
      issue_count: 2,
      resource_updated_at: 1.day.ago
    )

    @scan_wiki_page = accessibility_resource_scan_model(
      course:,
      wiki_page: wiki_page_model(course:),
      workflow_state: "queued",
      resource_name: "TheWiki",
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

        asc_values = json.map { |scan| scan[sort_param] }

        # Descending order
        get :index, params: { course_id: course.id, sort: sort_param, direction: "desc" }, format: :json
        expect(response).to have_http_status(:ok)
        desc_json = response.parsed_body
        expect(desc_json.length).to eq(3)

        desc_values = desc_json.map { |scan| scan[sort_param] }

        expect(desc_values).to eq(asc_values.reverse)
      end
    end

    it "sets scan_status and issue_count according to workflow_state" do
      # Create additional scans covering each workflow_state variant
      _queued_scan = accessibility_resource_scan_model(
        course:,
        wiki_page: wiki_page_model(course:),
        workflow_state: "queued",
        resource_name: "Queued Resource",
        resource_workflow_state: :published,
        issue_count: 10
      )

      _in_progress_scan = accessibility_resource_scan_model(
        course:,
        attachment: attachment_model(course:),
        workflow_state: "in_progress",
        resource_name: "In Progress Resource",
        resource_workflow_state: :unpublished,
        issue_count: 7
      )

      _completed_scan = accessibility_resource_scan_model(
        course:,
        wiki_page: wiki_page_model(course:),
        workflow_state: "completed",
        resource_name: "Completed Resource",
        resource_workflow_state: :published,
        issue_count: 3
      )

      get :index, params: { course_id: course.id }, format: :json
      expect(response).to have_http_status(:ok)

      json = response.parsed_body
      expect(json.length).to eq(6)

      queued_json = json.find { |scan| scan["resource_name"] == "Queued Resource" }
      expect(queued_json["scan_status"]).to eq("checking")
      expect(queued_json["issue_count"]).to be_nil

      in_progress_json = json.find { |scan| scan["resource_name"] == "In Progress Resource" }
      expect(in_progress_json["scan_status"]).to eq("checking")
      expect(in_progress_json["issue_count"]).to be_nil

      completed_json = json.find { |scan| scan["resource_name"] == "Completed Resource" }
      expect(completed_json["scan_status"]).to eq("idle")
      expect(completed_json["issue_count"]).to eq(3)
    end
  end
end

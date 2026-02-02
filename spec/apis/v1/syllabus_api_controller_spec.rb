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

require_relative "../../spec_helper"

describe SyllabusApiController, type: :request do
  before(:once) do
    course_with_teacher(active_all: true)
    @course.update!(syllabus_body: '<img src="test.jpg" />')
  end

  describe "POST /api/v1/courses/:course_id/syllabus/accessibility/scan" do
    let(:api_path) { "/api/v1/courses/#{@course.id}/syllabus/accessibility/scan" }

    context "when user has permission" do
      before do
        user_session(@teacher)
      end

      context "when accessibility checker is enabled" do
        before do
          @course.root_account.enable_feature!(:a11y_checker)
          @course.enable_feature!(:a11y_checker_eap)
        end

        it "returns accessibility scan results" do
          post api_path
          expect(response).to be_successful
          json = JSON.parse(response.body)
          expect(json).to have_key("workflow_state")
          expect(json).to have_key("issue_count")
        end

        it "creates a scan for syllabus resource" do
          expect do
            post api_path
          end.to change { AccessibilityResourceScan.count }.by(1)

          scan = AccessibilityResourceScan.last
          expect(scan.course_id).to eq(@course.id)
          expect(scan.is_syllabus).to be true
        end

        it "identifies accessibility issues in syllabus" do
          post api_path
          json = JSON.parse(response.body)
          expect(json["issue_count"]).to be > 0
        end
      end

      context "when accessibility checker is disabled" do
        before do
          @course.root_account.disable_feature!(:a11y_checker)
        end

        it "returns unauthorized" do
          post api_path
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "when user lacks permission" do
      before do
        course_with_student_logged_in(course: @course)
      end

      it "returns unauthorized" do
        @course.root_account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)
        post api_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when context is not a course" do
      it "handles invalid context gracefully" do
        user_session(@teacher)
        @course.root_account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        # Try with a non-existent course
        post "/api/v1/courses/999999999/syllabus/accessibility/scan"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with existing scan" do
      before do
        user_session(@teacher)
        @course.root_account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)

        # Create an existing scan
        @existing_scan = AccessibilityResourceScan.create!(
          course: @course,
          is_syllabus: true,
          workflow_state: "completed",
          resource_workflow_state: "published",
          issue_count: 1
        )
      end

      it "returns existing scan if still valid" do
        post api_path
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(@existing_scan.id)
      end
    end
  end

  describe "POST /api/v1/courses/:course_id/syllabus/accessibility/queue_scan" do
    let(:api_path) { "/api/v1/courses/#{@course.id}/syllabus/accessibility/queue_scan" }

    context "when user has permission" do
      before do
        user_session(@teacher)
      end

      context "when accessibility checker is enabled" do
        before do
          @course.root_account.enable_feature!(:a11y_checker)
          @course.enable_feature!(:a11y_checker_eap)
        end

        it "queues accessibility scan" do
          expect do
            post api_path
          end.to change { Delayed::Job.count }.by_at_least(1)

          expect(response).to be_successful
          json = JSON.parse(response.body)
          expect(json["workflow_state"]).to eq("queued")
        end

        it "creates a scan record with queued state" do
          expect do
            post api_path
          end.to change { AccessibilityResourceScan.count }.by(1)

          scan = AccessibilityResourceScan.last
          expect(scan.course_id).to eq(@course.id)
          expect(scan.is_syllabus).to be true
          expect(scan.workflow_state).to eq("queued")
        end
      end

      context "when accessibility checker is disabled" do
        before do
          @course.root_account.disable_feature!(:a11y_checker)
        end

        it "returns unauthorized" do
          post api_path
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "when user lacks permission" do
      before do
        course_with_student_logged_in(course: @course)
      end

      it "returns unauthorized" do
        @course.root_account.enable_feature!(:a11y_checker)
        @course.enable_feature!(:a11y_checker_eap)
        post api_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

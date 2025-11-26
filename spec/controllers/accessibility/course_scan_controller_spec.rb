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

RSpec.describe Accessibility::CourseScanController do
  let!(:course) { course_model }

  before do
    allow_any_instance_of(described_class).to receive(:require_user).and_return(true)
    allow_any_instance_of(described_class).to receive(:check_authorized_action).and_return(true)
    allow_any_instance_of(Course).to receive(:exceeds_accessibility_scan_limit?).and_return(false)
  end

  context "when a11y_checker feature flag disabled" do
    it "renders forbidden" do
      allow_any_instance_of(described_class).to receive(:check_authorized_action).and_call_original
      allow(course).to receive(:a11y_checker_enabled?).and_return(false)

      expect(controller).to receive(:render).with(status: :forbidden)
      controller.send(:check_authorized_action)
    end
  end

  describe "#show" do
    context "when no scan exists" do
      it "returns not found" do
        get :show, params: { course_id: course.id }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when a scan exists" do
      let!(:progress) do
        Progress.create!(tag: "course_accessibility_scan", context: course, workflow_state: "queued")
      end

      it "returns the progress information" do
        get :show, params: { course_id: course.id }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["id"]).to eq(progress.id)
        expect(json["workflow_state"]).to eq("queued")
      end
    end
  end

  describe "#create" do
    it "queues a scan and returns the progress" do
      post :create, params: { course_id: course.id }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["id"]).to be_present
      expect(json["workflow_state"]).to eq("queued")

      # Verify a progress record was created
      progress = Progress.find(json["id"])
      expect(progress.tag).to eq("course_accessibility_scan")
      expect(progress.context).to eq(course)
    end

    it "returns existing progress if scan is already queued" do
      existing_progress = Accessibility::CourseScanService.queue_course_scan(course)

      post :create, params: { course_id: course.id }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["id"]).to eq(existing_progress.id)
    end

    context "when the course does not exist" do
      it "returns a not found error" do
        post :create, params: { course_id: -1 }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the course exceeds scan limit" do
      it "returns a bad request error" do
        allow_any_instance_of(Course).to receive(:exceeds_accessibility_scan_limit?).and_return(true)

        post :create, params: { course_id: course.id }

        expect(response).to have_http_status(:bad_request)
        json = response.parsed_body
        expect(json["error"]).to eq("Course exceeds accessibility scan limit")
      end
    end
  end
end

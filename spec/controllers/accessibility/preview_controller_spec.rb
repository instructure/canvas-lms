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

require "spec_helper"

RSpec.describe Accessibility::PreviewController do
  describe "#create" do
    let!(:course) { Course.create! }
    let!(:user) { User.create! }
    let(:accessibility_issue_instance) { instance_double(Accessibility::Issue) }

    before do
      allow(controller).to receive_messages(require_context: true, require_user: true, validate_allowed: true)
      controller.instance_variable_set(:@context, course)
      controller.instance_variable_set(:@current_user, user)

      allow(Accessibility::Issue).to receive(:new).with(context: course).and_return(accessibility_issue_instance)
    end

    context "for a wiki page" do
      let!(:wiki_page) { course.wiki_pages.create!(title: "test page", body: "test body") }
      let(:update_params) do
        {
          "rule" => "some_rule",
          "content_type" => "WikiPage",
          "content_id" => wiki_page.id.to_s,
          "path" => "some_path",
          "value" => "some_value",

          "action" => "create",
          "course_id" => course.id.to_s,
          "controller" => "accessibility/preview",
          "format" => "json"
        }
      end
      let(:params) do
        {
          course_id: course.id,
          rule: "some_rule",
          content_type: "WikiPage",
          content_id: wiki_page.id.to_s,
          path: "some_path",
          value: "some_value"
        }
      end
      let(:response_data) { { json: { "result" => "success" }, status: :ok } }

      it "returns the correct response" do
        expect(accessibility_issue_instance).to receive(:update_preview).with(update_params).and_return(response_data)

        post :create, params:, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "result" => "success" })
      end
    end

    context "for an assignment" do
      let!(:assignment) { course.assignments.create! }
      let(:update_params) do
        {
          "rule" => "another_rule",
          "content_type" => "Assignment",
          "content_id" => assignment.id.to_s,
          "path" => "another_path",
          "value" => "another_value",

          "action" => "create",
          "course_id" => course.id.to_s,
          "controller" => "accessibility/preview",
          "format" => "json"
        }
      end
      let(:params) do
        {
          course_id: course.id,
          rule: "another_rule",
          content_type: "Assignment",
          content_id: assignment.id.to_s,
          path: "another_path",
          value: "another_value"
        }
      end
      let(:response_data) { { json: { "result" => "success" }, status: :ok } }

      it "returns the correct response" do
        expect(accessibility_issue_instance).to receive(:update_preview).with(update_params).and_return(response_data)

        post :create, params:, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "result" => "success" })
      end
    end

    context "with missing params" do
      let(:update_params) do
        {
          "rule" => "some_rule",
          "action" => "create",
          "controller" => "accessibility/preview",
          "course_id" => course.id.to_s,
          "format" => "json"
        }
      end
      let(:params) do
        {
          course_id: course.id,
          rule: "some_rule"
        }
      end
      let(:error_response) { { json: { "error" => "missing params" }, status: :bad_request } }

      it "returns an error" do
        expect(accessibility_issue_instance).to receive(:update_preview).with(update_params).and_return(error_response)

        post :create, params:, format: :json
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq({ "error" => "missing params" })
      end
    end
  end
end

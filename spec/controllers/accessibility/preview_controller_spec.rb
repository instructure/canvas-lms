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
      allow(controller).to receive_messages(require_context: true, require_user: true, check_authorized_action: true)
      controller.instance_variable_set(:@context, course)
      controller.instance_variable_set(:@current_user, user)

      allow(Accessibility::Issue).to receive(:new).with(context: course).and_return(accessibility_issue_instance)
    end

    context "for a wiki page" do
      let!(:wiki_page) { course.wiki_pages.create!(title: "test page", body: "test body") }
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
        expect(accessibility_issue_instance).to receive(:update_preview).with("some_rule", "WikiPage", wiki_page.id.to_s, "some_path", "some_value").and_return(response_data)

        post :create, params:, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "result" => "success" })
      end
    end

    context "for an assignment" do
      let!(:assignment) { course.assignments.create! }
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
        expect(accessibility_issue_instance).to receive(:update_preview).with("another_rule", "Assignment", assignment.id.to_s, "another_path", "another_value").and_return(response_data)

        post :create, params:, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "result" => "success" })
      end
    end

    context "with missing params" do
      let(:params) do
        {
          course_id: course.id,
          rule: "some_rule"
        }
      end
      let(:error_response) { { json: { "error" => "missing params" }, status: :bad_request } }

      it "returns an error" do
        expect(accessibility_issue_instance).to receive(:update_preview).with("some_rule", nil, nil, nil, nil).and_return(error_response)

        post :create, params:, format: :json
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq({ "error" => "missing params" })
      end
    end
  end

  describe "#show" do
    let!(:course) { Course.create! }
    let!(:user) { User.create! }

    before do
      allow(controller).to receive_messages(require_context: true, require_user: true, check_authorized_action: true)
      controller.instance_variable_set(:@context, course)
      controller.instance_variable_set(:@current_user, user)
    end

    context "for an assignment" do
      let!(:assignment) { course.assignments.create!(description: "Assignment description") }
      let(:params) do
        {
          course_id: course.id,
          content_type: "Assignment",
          content_id: assignment.id.to_s
        }
      end

      it "returns the assignment description" do
        get :show, params:, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "content" => "Assignment description" })
      end
    end

    context "for a wiki page" do
      let!(:wiki_page) { course.wiki_pages.create!(title: "Test Page", body: "Wiki page body") }
      let(:params) do
        {
          course_id: course.id,
          content_type: "Page",
          content_id: wiki_page.id.to_s
        }
      end

      it "returns the wiki page body" do
        get :show, params:, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "content" => "Wiki page body" })
      end
    end

    context "with unknown content type" do
      let(:params) do
        {
          course_id: course.id,
          content_type: "UnknownType",
          content_id: "123"
        }
      end

      it "returns an error for unknown content type" do
        get :show, params:, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq({ "error" => "Unknown content type: UnknownType" })
      end
    end

    context "with non-existent resource" do
      let(:params) do
        {
          course_id: course.id,
          content_type: "Assignment",
          content_id: "999999"
        }
      end

      it "returns not found for missing resource" do
        get :show, params:, format: :json
        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body).to eq({ "error" => "Resource 'Assignment' with id '999999' was not found." })
      end
    end

    context "with path parameter for element extraction" do
      let!(:wiki_page) { course.wiki_pages.create!(title: "Test Page", body: "<div><h1>Page Title</h1><p>Page content</p></div>") }

      context "when element exists" do
        let(:params) do
          {
            course_id: course.id,
            content_type: "Page",
            content_id: wiki_page.id.to_s,
            path: ".//h1"
          }
        end

        it "returns only the specified element" do
          get :show, params:, format: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq({ "content" => "<h1>Page Title</h1>" })
        end
      end

      context "when element does not exist" do
        let(:params) do
          {
            course_id: course.id,
            content_type: "Page",
            content_id: wiki_page.id.to_s,
            path: ".//nonexistent"
          }
        end

        it "returns element not found error" do
          get :show, params:, format: :json
          expect(response).to have_http_status(:not_found)
          expect(response.parsed_body).to eq({ "error" => "Element not found" })
        end
      end

      context "when path is empty string" do
        let(:params) do
          {
            course_id: course.id,
            content_type: "Page",
            content_id: wiki_page.id.to_s,
            path: ""
          }
        end

        it "returns full content (treats empty path as no path)" do
          get :show, params:, format: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq({ "content" => "<div><h1>Page Title</h1><p>Page content</p></div>" })
        end
      end

      context "for assignment with path" do
        let!(:assignment) { course.assignments.create!(description: "<div><h2>Assignment Title</h2><p>Assignment description</p></div>") }
        let(:params) do
          {
            course_id: course.id,
            content_type: "Assignment",
            content_id: assignment.id.to_s,
            path: ".//h2"
          }
        end

        it "returns only the specified element from assignment" do
          get :show, params:, format: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq({ "content" => "<h2>Assignment Title</h2>" })
        end
      end
    end
  end
end

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
  include Factories

  describe "feature_flag" do
    let(:course) { Course.create! }

    context "when a11y_checker feature flag disabled" do
      it "renders forbidden" do
        allow(course).to receive(:a11y_checker_enabled?).and_return(false)

        expect(controller).to receive(:render).with(status: :forbidden)
        controller.send(:check_authorized_action)
      end
    end
  end

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

    context "with missing issue_id parameter" do
      let(:params) do
        {
          course_id: course.id
        }
      end

      it "returns bad request" do
        get :show, params:, format: :json
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to be_empty
      end
    end

    context "with non-existent issue_id" do
      let(:params) do
        {
          course_id: course.id,
          issue_id: "99999"
        }
      end

      it "returns not found" do
        get :show, params:, format: :json
        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["error"]).to be_present
      end
    end

    context "for an assignment" do
      let!(:assignment) { course.assignments.create!(description: "Assignment description") }
      let!(:issue) { accessibility_issue_model(course:, context: assignment, node_path: nil) }
      let(:params) do
        {
          course_id: course.id,
          issue_id: issue.id.to_s
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
      let!(:issue) { accessibility_issue_model(course:, context: wiki_page, node_path: nil) }
      let(:params) do
        {
          course_id: course.id,
          issue_id: issue.id.to_s
        }
      end

      it "returns the wiki page body" do
        get :show, params:, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "content" => "Wiki page body" })
      end
    end

    context "with unknown content type" do
      let!(:wiki_page) { course.wiki_pages.create!(title: "Test Page", body: "Test content") }
      let!(:issue) { accessibility_issue_model(course:, context: wiki_page, node_path: nil) }
      let(:params) do
        {
          course_id: course.id,
          issue_id: issue.id.to_s
        }
      end

      it "returns an error for unknown content type" do
        allow_any_instance_of(Accessibility::ContentLoader).to receive(:resource_html_content).and_raise(
          Accessibility::ContentLoader::UnsupportedResourceTypeError.new("Unsupported resource type: Course")
        )

        get :show, params:, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to include("Unsupported resource type")
      end
    end

    context "with path parameter for element extraction" do
      let!(:wiki_page) { course.wiki_pages.create!(title: "Test Page", body: "<div><h1>Page Title</h1><p>Page content</p></div>") }

      context "when element exists" do
        let!(:issue) { accessibility_issue_model(course:, context: wiki_page, node_path: ".//h1") }
        let(:params) do
          {
            course_id: course.id,
            issue_id: issue.id.to_s
          }
        end

        it "returns only the specified element" do
          get :show, params:, format: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq({ "content" => "<h1>Page Title</h1>" })
        end
      end

      context "when element does not exist" do
        let!(:issue) { accessibility_issue_model(course:, context: wiki_page, node_path: ".//nonexistent") }
        let(:params) do
          {
            course_id: course.id,
            issue_id: issue.id.to_s
          }
        end

        it "returns element not found error" do
          get :show, params:, format: :json
          expect(response).to have_http_status(:not_found)
          expect(response.parsed_body["error"]).to include("Element not found")
        end
      end

      context "when path is empty string" do
        let!(:issue) { accessibility_issue_model(course:, context: wiki_page, node_path: "") }
        let(:params) do
          {
            course_id: course.id,
            issue_id: issue.id.to_s
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
        let!(:issue) { accessibility_issue_model(course:, context: assignment, node_path: ".//h2") }
        let(:params) do
          {
            course_id: course.id,
            issue_id: issue.id.to_s
          }
        end

        it "returns only the specified element from assignment" do
          get :show, params:, format: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq({ "content" => "<h2>Assignment Title</h2>" })
        end
      end

      context "with rule_id parameter" do
        let!(:wiki_page) { course.wiki_pages.create!(title: "Test Page", body: "<div><h1>Test Header</h1></div>") }
        let!(:issue) { accessibility_issue_model(course:, context: wiki_page, rule_type: "img-alt", node_path: ".//h1") }
        let(:mock_rule_instance) { double("RuleInstance") }
        let(:mock_rule_registry) { { "img-alt" => mock_rule_instance } }
        let(:params) do
          {
            course_id: course.id,
            issue_id: issue.id.to_s
          }
        end

        before do
          allow(Accessibility::Rule).to receive(:registry).and_return(mock_rule_registry)
          allow(mock_rule_instance).to receive(:issue_preview).and_return("<h1>Test Header</h1><p>Additional context</p>")
        end

        it "passes rule_id to ContentLoader and uses rule's issue_preview" do
          get :show, params:, format: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body["content"]).to eq("<h1>Test Header</h1><p>Additional context</p>")
        end
      end

      context "with rule_id but no matching rule" do
        let!(:wiki_page) { course.wiki_pages.create!(title: "Test Page", body: "<div><h1>Title</h1></div>") }
        let!(:issue) { accessibility_issue_model(course:, context: wiki_page, rule_type: "img-alt", node_path: ".//h1") }
        let(:params) do
          {
            course_id: course.id,
            issue_id: issue.id.to_s
          }
        end

        before do
          allow(Accessibility::Rule).to receive(:registry).and_return({})
        end

        it "falls back to default HTML when rule not found" do
          get :show, params:, format: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq({ "content" => "<h1>Title</h1>" })
        end
      end

      context "with rule that provides metadata" do
        let!(:wiki_page) do
          course.wiki_pages.create!(
            title: "Test Page",
            body: '<div><span style="color: #FF0000; background-color: #FFFFFF;">Low contrast text</span></div>'
          )
        end
        let!(:issue) { accessibility_issue_model(course:, context: wiki_page, rule_type: "small-text-contrast", node_path: ".//span") }
        let(:mock_rule_instance) { double("RuleInstance") }
        let(:mock_rule_registry) { { "small-text-contrast" => mock_rule_instance } }
        let(:params) do
          {
            course_id: course.id,
            issue_id: issue.id.to_s
          }
        end

        before do
          allow(Accessibility::Rule).to receive(:registry).and_return(mock_rule_registry)
          allow(mock_rule_instance).to receive_messages(
            issue_preview: '<span style="color: #FF0000; background-color: #FFFFFF;">Low contrast text</span>',
            issue_metadata: { foreground: "#FF0000", background: "#FFFFFF" }
          )
        end

        it "includes metadata in the response" do
          get :show, params:, format: :json
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq({
                                               "content" => '<span style="color: #FF0000; background-color: #FFFFFF;">Low contrast text</span>',
                                               "foreground" => "#FF0000",
                                               "background" => "#FFFFFF"
                                             })
        end
      end
    end
  end
end

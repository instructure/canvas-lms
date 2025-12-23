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

describe AccessibilityIssuesController do
  let(:course) { course_model }
  let(:wiki_page) do
    wiki_page_model(course:, title: "Wiki Page", body: "<div><h1>Document Title</h1></div>")
  end
  let(:scan) { accessibility_resource_scan_model(course:, context: wiki_page, issue_count: 1) }
  let!(:issue) do
    accessibility_issue_model(
      course:,
      accessibility_resource_scan: scan,
      rule_type: Accessibility::Rules::HeadingsStartAtH2Rule.id,
      node_path: "./div/h1"
    )
  end

  before do
    allow_any_instance_of(described_class).to receive(:require_user).and_return(true)
    allow_any_instance_of(described_class).to receive(:check_authorized_action).and_return(true)
  end

  describe "PATCH #update" do
    context "when issue cannot be found" do
      before do
        patch :update,
              params: {
                course_id: course.id,
                id: 1
              },
              format: :json
      end

      it "returns a 404 status" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when workflow_state is invalid" do
      before do
        patch :update,
              params: {
                course_id: course.id,
                id: issue.id,
                workflow_state: "invalid_state"
              },
              format: :json
      end

      it "returns a 422 status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders an error message" do
        expect(response.parsed_body["error"]).to eq("Invalid workflow_state")
      end
    end

    context "when workflow_state is 'resolved'" do
      context "when value key is not provided" do
        before do
          patch :update,
                params: {
                  course_id: course.id,
                  id: issue.id,
                  workflow_state: "resolved"
                },
                format: :json
        end

        it "returns a 422 status" do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "renders an error message" do
          expect(response.parsed_body["error"]).to eq("Value is required for resolved state")
        end
      end

      context "when value is an empty string" do
        before do
          patch :update,
                params: {
                  course_id: course.id,
                  id: issue.id,
                  workflow_state: "resolved",
                  value: ""
                },
                format: :json
        end

        it "returns a 422 status" do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "renders an error message" do
          expect(response.parsed_body["error"]).to eq("Value is required for resolved state")
        end
      end

      context "when value is whitespace only" do
        before do
          patch :update,
                params: {
                  course_id: course.id,
                  id: issue.id,
                  workflow_state: "resolved",
                  value: "   "
                },
                format: :json
        end

        it "returns a 422 status" do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "renders an error message" do
          expect(response.parsed_body["error"]).to eq("Value is required for resolved state")
        end
      end

      context "when value is nil for a rule that allows it" do
        let(:img_wiki_page) do
          wiki_page_model(course:, title: "Image Wiki Page", body: "<div><img src='test.jpg' /></div>")
        end
        let(:img_scan) { accessibility_resource_scan_model(course:, context: img_wiki_page, issue_count: 1) }
        let(:img_issue) do
          accessibility_issue_model(
            course:,
            accessibility_resource_scan: img_scan,
            rule_type: Accessibility::Rules::ImgAltRule.id,
            node_path: ".//img"
          )
        end

        before do
          patch :update,
                params: {
                  course_id: course.id,
                  id: img_issue.id
                },
                body: { workflow_state: "resolved", value: nil }.to_json,
                as: :json
        end

        it "updates the workflow_state" do
          expect(img_issue.reload.workflow_state).to eq "resolved"
        end

        it "returns a no content status" do
          expect(response).to have_http_status(:no_content)
        end
      end

      context "when value is nil for ImgAltFilenameRule" do
        let(:img_wiki_page) do
          wiki_page_model(course:, title: "Image Wiki Page", body: "<div><img src='test.jpg' alt='test.jpg' /></div>")
        end
        let(:img_scan) { accessibility_resource_scan_model(course:, context: img_wiki_page, issue_count: 1) }
        let(:img_issue) do
          accessibility_issue_model(
            course:,
            accessibility_resource_scan: img_scan,
            rule_type: Accessibility::Rules::ImgAltFilenameRule.id,
            node_path: ".//img"
          )
        end

        before do
          patch :update,
                params: {
                  course_id: course.id,
                  id: img_issue.id
                },
                body: { workflow_state: "resolved", value: nil }.to_json,
                as: :json
        end

        it "updates the workflow_state" do
          expect(img_issue.reload.workflow_state).to eq "resolved"
        end

        it "returns a no content status" do
          expect(response).to have_http_status(:no_content)
        end
      end

      context "when value is provided" do
        context "when applying the fix fails" do
          before do
            patch :update,
                  params: {
                    course_id: course.id,
                    id: issue.id,
                    workflow_state: "resolved",
                    value: "Invalid value"
                  },
                  format: :json
          end

          it "returns a 400 status" do
            expect(response).to have_http_status(:bad_request)
          end

          it "renders an error message" do
            expect(response.parsed_body["error"]).to eq("Invalid value for form: Invalid value")
          end
        end

        context "when applying the fix succeeds" do
          before do
            patch :update,
                  params: {
                    course_id: course.id,
                    id: issue.id,
                    workflow_state: "resolved",
                    value: "Change it to Heading 2"
                  },
                  format: :json
          end

          it "updates the workflow_state" do
            expect(issue.reload.workflow_state).to eq "resolved"
          end

          it "returns a no content status" do
            expect(response).to have_http_status(:no_content)
          end

          it "updates the issue count" do
            expect(scan.reload.issue_count).to eq 0
          end
        end
      end

      context "with linked files, no user (happens after content migration), and no attachment associations" do
        before do
          user_session(@teacher)
        end

        let(:attachment) { attachment_model(context: course, uploaded_data: fixture_file_upload("cn_image.jpg")) }
        let(:img_wiki_page) do
          body = <<~HTML
            <div><img src='/courses/#{course.id}/files/#{attachment.id}/preview' /></div>
          HTML
          wiki_page_model(course:, title: "Image Wiki Page", body:, skip_attachment_association_update: true)
        end
        let(:img_scan) { accessibility_resource_scan_model(course:, context: img_wiki_page, issue_count: 1) }
        let(:img_issue) do
          accessibility_issue_model(
            course:,
            accessibility_resource_scan: img_scan,
            rule_type: Accessibility::Rules::ImgAltFilenameRule.id,
            node_path: ".//img"
          )
        end

        it "successfully applies the fix" do
          patch :update, params: { course_id: course.id, id: img_issue.id }, body: { workflow_state: "resolved", value: nil }.to_json, as: :json
          expect(response).to have_http_status(:no_content)
        end
      end
    end

    context "when workflow_state is 'dismissed'" do
      before do
        patch :update,
              params: {
                course_id: course.id,
                id: issue.id,
                workflow_state: "dismissed"
              },
              format: :json
      end

      it "updates the workflow_state" do
        expect(issue.reload.workflow_state).to eq "dismissed"
      end

      it "returns a no content status" do
        expect(response).to have_http_status(:no_content)
      end

      it "updates the issue count" do
        expect(scan.reload.issue_count).to eq 0
      end
    end
  end
end

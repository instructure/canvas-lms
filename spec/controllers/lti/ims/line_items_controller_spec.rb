# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "concerns/advantage_services_shared_context"
require_relative "concerns/advantage_services_shared_examples"
require_relative "concerns/lti_services_shared_examples"

module Lti
  module IMS
    RSpec.describe LineItemsController do
      include_context "advantage services context"

      let(:context) { course }
      let(:unknown_context_id) { (Course.maximum(:id) || 0) + 1 }
      let(:resource_link) do
        if tool.present? && tool.use_1_3?
          resource_link_model(overrides: { resource_link_uuid: assignment.lti_context_id })
        else
          resource_link_model
        end
      end
      let(:assignment) do
        opts = { course: }
        if tool.present?
          opts[:submission_types] = "external_tool"
          opts[:external_tool_tag_attributes] = {
            url: tool.url,
            content_type: "context_external_tool",
            content_id: tool.id
          }
        end
        assignment_model(opts)
      end
      let(:parsed_response_body) { response.parsed_body }
      let(:label) { "Originality Score" }
      let(:tag) { "some_tag" }
      let(:resource_id) { "orig-123" }
      let(:score_max) { 50 }
      let(:scope_to_remove) { "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem" }

      before do
        allow_any_instance_of(Account).to receive(:environment_specific_domain)
          .and_return("test.host")

        assignment
      end

      shared_examples "assignment with wrong tool" do
        let(:other_tool) do
          ContextExternalTool.create!(
            context: tool_context,
            consumer_key: "key",
            shared_secret: "secret",
            name: "wrong tool",
            url: "http://www.wrong_tool.com/launch",
            developer_key: DeveloperKey.create!,
            lti_version: "1.3",
            workflow_state: "public"
          )
        end
        let(:line_item) do
          line_item_model(
            course:,
            with_resource_link: true,
            tool: other_tool
          )
        end

        it "returns a precondition_failed" do
          send_request
          expect(response).to have_http_status :precondition_failed
        end
      end

      describe "#create" do
        let(:start_date_time) { 1.day.ago }
        let(:end_date_time) { Time.zone.now }
        let(:params_overrides) do
          {
            scoreMaximum: score_max,
            label:,
            startDateTime: start_date_time.iso8601,
            endDateTime: end_date_time.iso8601,
            resourceId: resource_id,
            tag:,
            resourceLinkId: assignment.lti_context_id,
            course_id: context_id
          }
        end
        let(:action) { :create }
        let(:http_success_status) { :created }
        let(:content_type) { "application/vnd.ims.lis.v2.lineitem+json" }

        it_behaves_like "lti services"
        it_behaves_like "advantage services"

        before do
          resource_link.original_context_external_tool.update!(developer_key:)
          resource_link.line_items.create(
            score_maximum: 1,
            label: "Canvas Created",
            assignment:
          )
        end

        shared_examples "the line item create endpoint" do
          it "creates a new line" do
            expect do
              send_request
            end.to change(Lti::LineItem, :count).by(1)
          end

          it "sets coupled to false on the new line item" do
            send_request
            expect(Lti::LineItem.last.coupled).to be(false)
          end

          it "responds with the line item mime type" do
            send_request
            expect(response.headers["Content-Type"]).to include described_class::MIME_TYPE
          end
        end

        context "when using the declarative model" do
          it_behaves_like "the line item create endpoint"

          it "properly formats the response" do
            send_request
            item = Lti::LineItem.find(parsed_response_body["id"].split("/").last)

            expected_response = {
              id: "http://test.host/api/lti/courses/#{course.id}/line_items/#{item.id}",
              scoreMaximum: score_max.to_f,
              label:,
              resourceId: resource_id,
              tag:,
              startDateTime: start_date_time.iso8601,
              endDateTime: end_date_time.iso8601,
              resourceLinkId: item.resource_link.resource_link_uuid
            }.with_indifferent_access

            expect(parsed_response_body).to eq expected_response
          end

          it "uses the Account#domain in the line item id" do
            allow_any_instance_of(Account).to receive(:environment_specific_domain).and_return("canonical.host")
            send_request
            expect(parsed_response_body["id"]).to start_with(
              "http://canonical.host/api/lti/courses/#{course.id}/line_items/"
            )
          end

          it "associates the line item with the correct assignment" do
            send_request
            body = parsed_response_body
            expect(Lti::LineItem.find(body["id"].split("/").last).assignment).to eq assignment
          end

          it "associates the line item with the correct resource link" do
            send_request
            body = parsed_response_body
            item = Lti::LineItem.find(body["id"].split("/").last)
            expect(item.resource_link).to eq resource_link
          end

          it "does not create a new assignment" do
            assignment
            expect do
              send_request
            end.not_to change(Assignment, :count)
          end

          it "renders precondition failed if ResourceLink has no LineItems" do
            resource_link.line_items.destroy_all
            send_request
            expect(response).to be_precondition_failed
          end

          context do
            let(:params_overrides) { super().merge(resourceLinkId: SecureRandom.uuid) }

            it "renders not found if no matching ResourceLink for the specified resourceLinkId" do
              send_request
              expect(response).to be_not_found
            end
          end
        end

        context "when using the uncoupled model" do
          let(:params_overrides) { super().except(:resourceLinkId) }
          let(:item) { Lti::LineItem.find(parsed_response_body["id"].split("/").last) }

          it_behaves_like "the line item create endpoint"

          it "properly formats the response" do
            send_request
            item = Lti::LineItem.find(parsed_response_body["id"].split("/").last)

            expected_response = {
              id: "http://test.host/api/lti/courses/#{course.id}/line_items/#{item.id}",
              scoreMaximum: score_max.to_f,
              label:,
              resourceId: resource_id,
              tag:,
              startDateTime: start_date_time.iso8601,
              endDateTime: end_date_time.iso8601
            }.with_indifferent_access

            expect(parsed_response_body).to eq expected_response
          end

          it "creates a new assignment" do
            assignment
            expect do
              send_request
            end.to change { Assignment.count }.by(1)
          end

          it "does not create a resource_link record" do
            expect do
              send_request
            end.not_to change { Lti::ResourceLink.count }
          end

          context "when a new assignment is created" do
            before do
              send_request
            end

            it "sets the score maximum on the new assignment" do
              expect(item.assignment.points_possible).to eq score_max
            end

            it "sets the submission type on the new assignment" do
              expect(item.assignment.submission_types).to eq "none"
            end

            it "does not attach a resource_link" do
              expect(item.resource_link).to be_blank
            end

            it "sets the name for the assignment" do
              expect(item.assignment.name).to eq label
            end

            it "sets the context of the new assignment" do
              expect(item.assignment.context).to eq course
            end

            it "sets the unlock_at for the assignment" do
              expect(item.assignment.unlock_at).to be_within(1.second).of start_date_time
            end

            it "sets the due_at for the assignment" do
              expect(item.assignment.due_at).to be_within(1.second).of end_date_time
            end

            context "when submission type is external tool and the URL is not for an existing tool" do
              # I'm not sure what the expected behavior is here exactly. We currently
              # create an assignment and line item but no resource link, tool for the ContentTag --
              # ContentExternalTool.from_content_tag(assignment.external_tool_tag, course) is nil

              let(:params_overrides) do
                super().merge(LineItem::AGS_EXT_SUBMISSION_TYPE => {
                                type: "external_tool",
                                external_tool_url: "http://www.google.com"
                              })
              end

              it "sets the assignment submission type to external tool" do
                expect(item.assignment.submission_types).to eq "external_tool"
              end

              it "sets the assignment external url" do
                expect(item.assignment.external_tool_tag.url).to eq "http://www.google.com"
              end

              it "sets the extension on return" do
                expect(json[LineItem::AGS_EXT_SUBMISSION_TYPE][:external_tool_url]).to eq "http://www.google.com"
              end
            end

            context "when submission type is invalid" do
              let(:params_overrides) do
                super().merge(LineItem::AGS_EXT_SUBMISSION_TYPE => {
                                type: "a_bad_submission_type",
                                external_tool_url: "http://www.google.com"
                              })
              end

              it "returns a 400 error response code" do
                expect(response).to have_http_status(:bad_request)
              end
            end
          end

          context "when submission type is external tool and and tool URL matches a tool" do
            let(:params_overrides) do
              super().merge(LineItem::AGS_EXT_SUBMISSION_TYPE => {
                              type: "external_tool",
                              external_tool_url: tool.url
                            })
            end

            it_behaves_like "the line item create endpoint"

            it "creates exactly one assignment and resource link" do
              expect do
                send_request
              end.to change(Assignment, :count).by(1)
                                               .and change(Lti::ResourceLink, :count).by(1)
            end

            it "creates a line item with resource link, tag, and extensions" do
              send_request
              expect(item.resource_link).to_not be_blank
              expect(item.resource_link.resource_link_uuid).to_not be_blank
              expect(item.tag).to_not be_blank
              expect(item.extensions).to_not be_blank
            end

            it "returns the resource link in the response" do
              send_request
              expected_response = {
                "https://canvas.instructure.com/lti/submission_type" => {
                  external_tool_url: tool.url,
                  type: "external_tool"
                },
                :id => "http://test.host/api/lti/courses/#{course.id}/line_items/#{item.id}",
                :scoreMaximum => score_max.to_f,
                :label => label,
                :resourceId => resource_id,
                :tag => tag,
                :startDateTime => start_date_time.iso8601,
                :endDateTime => end_date_time.iso8601,
                :resourceLinkId => item.resource_link.resource_link_uuid
              }.with_indifferent_access

              expect(parsed_response_body).to eq expected_response
            end

            it "sets the assignment submission type to external tool" do
              send_request
              expect(item.assignment.submission_types).to eq "external_tool"
            end

            it "sets the assignment external url" do
              send_request
              expect(item.assignment.external_tool_tag.url).to eq tool.url
            end

            it "sets the extension on return" do
              send_request
              expect(json[LineItem::AGS_EXT_SUBMISSION_TYPE][:external_tool_url]).to eq tool.url
            end
          end
        end
      end

      describe "#update" do
        let(:line_item) do
          line_item_model(
            assignment:,
            resource_link:
          )
        end
        let(:line_item_id) { line_item.id }
        let(:params_overrides) do
          {
            id: line_item_id,
            course_id: context_id
          }
        end
        let(:action) { :update }

        it_behaves_like "lti services"
        it_behaves_like "advantage services"
        it_behaves_like "assignment with wrong tool"

        context "with score_maximum" do
          let(:new_score_maximum) { 88.2 }
          let(:params_overrides) { super().merge(scoreMaximum: new_score_maximum) }
          let(:line_item) { assignment.line_items.first }

          it "updates the score maximum" do
            send_request
            body = parsed_response_body
            expect(body["scoreMaximum"]).to eq new_score_maximum
          end

          it "updates the assignment points_possible" do
            send_request
            expect(line_item.reload.assignment.points_possible).to eq new_score_maximum
          end

          context "if ResourceLink is absent" do
            before do
              line_item.update!(resource_link: nil)
            end

            it "updates the assignment points_possible" do
              send_request
              expect(line_item.reload.assignment.points_possible).to eq new_score_maximum
            end
          end
        end

        context "with label" do
          let(:new_label) { "a new label!" }
          let(:params_overrides) { super().merge(label: new_label) }
          let(:line_item) { assignment.line_items.first }

          it "updates the label" do
            send_request
            expect(line_item.reload.label).to eq new_label
          end

          it "updates the assignment name" do
            send_request
            expect(line_item.reload.assignment.name).to eq "a new label!"
          end

          context "if ResourceLink is absent" do
            before do
              line_item.update!(resource_link: nil)
            end

            it "updates the assignment name" do
              send_request
              expect(line_item.reload.assignment.name).to eq new_label
            end
          end
        end

        context "if not the default line item" do
          let(:line_item_two) do
            li = line_item_model(resource_link:, assignment:)
            li.update!(created_at: line_item.created_at + 5.seconds)
            li
          end
          let(:line_item_id) { line_item_two.id }
          let(:new_label) { "a new label!" }
          let(:params_overrides) { super().merge(label: new_label) }

          it "does not update the assignment name" do
            original_name = assignment.name
            send_request
            expect(line_item.reload.assignment.name).to eq original_name
          end
        end

        context "with startDateTime" do
          let(:line_item) { assignment.line_items.find(&:assignment_line_item?) }
          let(:start_date_time) { 1.day.ago }
          let(:params_overrides) { super().merge(startDateTime: start_date_time.iso8601) }

          it "updates the assignment unlock_at" do
            send_request
            expect(line_item.reload.assignment.unlock_at).to be_within(1.second).of start_date_time
          end
        end

        context "with endDateTime" do
          let(:line_item) { assignment.line_items.find(&:assignment_line_item?) }
          let(:end_date_time) { 1.day.from_now }
          let(:params_overrides) { super().merge(endDateTime: end_date_time.iso8601) }

          it "updates the assignment due_at" do
            send_request
            expect(line_item.reload.assignment.due_at).to be_within(1.second).of end_date_time
          end
        end

        context "with resourceId" do
          let(:new_resource_id) { "resource-id" }
          let(:params_overrides) { super().merge(resourceId: new_resource_id) }

          it "updates the resourceId" do
            send_request
            body = parsed_response_body
            expect(body["resourceId"]).to eq new_resource_id
          end
        end

        context "with tag" do
          let(:new_tag) { "New Tag" }
          let(:params_overrides) { super().merge(tag: new_tag) }

          it "updates the tag" do
            send_request
            body = parsed_response_body
            expect(body["tag"]).to eq new_tag
          end
        end

        context "with resourceLinkId" do
          let(:new_resource_link_id) do
            a = assignment_model
            a.lti_context_id
          end
          let(:params_overrides) { super().merge(resourceLinkId: new_resource_link_id) }

          it "responds with precondition failed message if a non-matching resourceLinkId is included" do
            send_request
            expect(response).to be_precondition_failed
          end

          it "includes an error message if a non-mataching resourceLinkId is included" do
            send_request
            error_message = parsed_response_body.dig("errors", "message")
            expect(error_message).to eq "The specified LTI link ID is not associated with the line item."
          end
        end

        it "correctly formats the requested line item" do
          send_request

          expected_response = {
            id: "http://test.host/api/lti/courses/#{course.id}/line_items/#{line_item.id}",
            scoreMaximum: 10.0,
            label: "Test Line Item",
            resourceLinkId: line_item.resource_link.resource_link_uuid
          }.with_indifferent_access

          expect(parsed_response_body).to eq expected_response
        end
      end

      describe "#show" do
        let!(:line_item) do
          line_item_model(
            assignment:,
            resource_link:,
            tag:
          )
        end
        let(:line_item_id) { line_item.id }
        let(:params_overrides) do
          {
            id: line_item_id,
            course_id: context_id
          }
        end
        let(:action) { :show }
        let(:scope_to_remove) do
          [
            "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
            "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly"
          ]
        end

        it_behaves_like "lti services"
        it_behaves_like "advantage services"
        it_behaves_like "assignment with wrong tool"

        it "correctly formats the requested line item" do
          send_request
          expected_response = {
            id: "http://test.host/api/lti/courses/#{course.id}/line_items/#{line_item.id}",
            scoreMaximum: 10.0,
            label: "Test Line Item",
            tag:,
            resourceLinkId: line_item.resource_link.resource_link_uuid
          }.with_indifferent_access
          expect(parsed_response_body).to eq expected_response
        end

        context do
          let(:context_id) { course_model.id }

          it "responds with 404 if the line item is not found in the course" do
            send_request
            expect(response).to be_not_found
          end
        end

        context do
          let(:line_item_id) {  Lti::LineItem.maximum(:id) + 1 }

          it "responds with 404 if the line item does not exist" do
            send_request
            expect(response).to be_not_found
          end
        end

        context do
          let(:context_id) { Course.last.id + 1 }

          it "responds with 404 if the course does not exist" do
            send_request
            expect(response).to be_not_found
          end
        end

        it "responds with the line item mime type" do
          send_request
          expect(response.headers["Content-Type"]).to include described_class::MIME_TYPE
        end

        context "when the assignment is deleted" do
          before do
            assignment.destroy!
          end

          it "responds with 404" do
            send_request
            expect(response).to be_not_found
          end
        end

        context "without include=launch_url parameter" do
          it "does not include launch url extension" do
            send_request
            expect(parsed_response_body).not_to have_key(Lti::LineItem::AGS_EXT_LAUNCH_URL)
          end
        end

        context "with include[]=launch_url parameter" do
          let(:params_overrides) { super().merge({ "include[]" => "launch_url" }) }

          it "includes launch url extension in line item json" do
            send_request
            expect(parsed_response_body).to include(Lti::LineItem::AGS_EXT_LAUNCH_URL => tool.url)
          end
        end
      end

      describe "#index" do
        let(:params_overrides) do
          {
            course_id: context_id
          }
        end
        let(:action) { :index }
        # The following "let!" declarations are used to provide a
        # diverse pool of line items when testing the queries in
        # the specs that follow.
        let!(:line_item) do
          assignment.line_items.first
        end
        let!(:line_item_with_tag) do
          line_item_model(
            assignment:,
            tag:
          )
        end
        let!(:line_item_with_resource_id) do
          line_item_model(
            assignment:,
            resource_id:
          )
        end
        let!(:line_item_with_resource_link_id) do
          line_item_model(
            assignment:,
            resource_link:
          )
        end
        let(:line_item_list) do
          parsed_response_body.map { |li| LineItem.find(li["id"].split("/").last) }
        end
        let(:scope_to_remove) do
          [
            "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
            "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly"
          ]
        end
        let(:expected_mime_type) { described_class::CONTAINER_MIME_TYPE }

        it_behaves_like "lti services"
        it_behaves_like "advantage services"

        context do
          let(:context_id) { Course.last.id + 1 }

          it "responds with 404 if context does not exist" do
            send_request
            expect(response).to be_not_found
          end
        end

        it "includes all associated line items in the course" do
          send_request
          expect(line_item_list).to match_array([
                                                  line_item,
                                                  line_item_with_tag,
                                                  line_item_with_resource_id,
                                                  line_item_with_resource_link_id
                                                ])
        end

        context do
          let(:params_overrides) { super().merge(tag:) }

          it "correctly queries by tag" do
            send_request
            expect(line_item_list).to match_array([
                                                    line_item_with_tag
                                                  ])
          end
        end

        context do
          let(:params_overrides) { super().merge(resource_id:) }

          it "correctly queries by resource_id" do
            send_request
            expect(line_item_list).to match_array([
                                                    line_item_with_resource_id
                                                  ])
          end
        end

        context do
          let(:line_item_new_lti_link) do
            line_item_model(
              course:,
              with_resource_link: true,
              tool:
            )
          end
          let(:params_overrides) { super().merge(resource_link_id: line_item_new_lti_link.resource_link.resource_link_uuid) }

          it "correctly queries by resource_link_id" do
            send_request
            expect(line_item_list).to match_array([
                                                    line_item_new_lti_link.assignment.line_items.first,
                                                    line_item_new_lti_link
                                                  ])
          end
        end

        context do
          let(:params_overrides) { super().merge(tag:, resource_id:) }

          it "allows querying by multiple valid fields at the same time" do
            tag_and_resource = line_item_model(
              assignment:,
              tag:,
              resource_id:
            )
            send_request
            expect(line_item_list).to match_array([
                                                    tag_and_resource
                                                  ])
          end
        end

        it "responds with the correct mime type" do
          send_request
          expect(response.headers["Content-Type"]).to include described_class::CONTAINER_MIME_TYPE
        end

        it "includes pagination headers" do
          send_request
          expect(response.headers).to have_key("Link")
        end

        context "without include=launch_url parameter" do
          it "does not include launch url extension" do
            send_request
            expect(parsed_response_body).not_to include(have_key(Lti::LineItem::AGS_EXT_LAUNCH_URL))
          end
        end

        context "with include[]=launch_url parameter" do
          let(:params_overrides) { super().merge({ "include[]" => "launch_url" }) }

          it "includes launch url extension in line item json" do
            send_request
            expect(parsed_response_body).to all(include(Lti::LineItem::AGS_EXT_LAUNCH_URL => tool.url))
          end
        end
      end

      describe "destroy" do
        let(:line_item_id) { line_item.id }
        let(:params_overrides) do
          {
            course_id: context_id,
            id: line_item_id
          }
        end
        let(:action) { :destroy }

        shared_examples "the line item destroy endpoint" do
          it_behaves_like "assignment with wrong tool"

          it "deletes the correct line item" do
            send_request
            expect(Lti::LineItem.active.find_by(id: line_item_id)).to be_nil
          end

          it "responds with no content" do
            send_request
            expect(response).to be_no_content
          end
        end

        context "when using the coupled model" do
          let(:coupled_line_item) do
            assignment.line_items.first.update!(
              tag:,
              resource_id:,
              coupled: true
            )
            assignment.line_items.first
          end

          let!(:second_line_item) do
            line_item_model(
              assignment:,
              resource_link:,
              tag:,
              resource_id:,
              coupled: false
            )
          end

          context "when destroying the default line item" do
            let(:line_item) { coupled_line_item }

            it "returns unauthorized" do
              send_request
              expect(response).to be_unauthorized
              expect(Lti::LineItem.active.find_by(id: line_item_id)).not_to be_nil
            end
          end

          context "when destroying an extra line item" do
            let(:line_item) do
              second_line_item
            end

            it_behaves_like "the line item destroy endpoint"
          end
        end

        context "when the line item is a tool-created (uncoupled) assignment line item" do
          let(:line_item) do
            assignment.line_items.first.update!(
              tag:,
              resource_id:,
              coupled: false
            )
            assignment.line_items.first
          end

          it_behaves_like "the line item destroy endpoint"

          it "deletes the resource link and assignment" do
            assignment_id = line_item.assignment_id
            resource_link_id = line_item.lti_resource_link_id
            send_request
            expect(Lti::LineItem.active.find_by(id: line_item_id)).to be_nil
            expect(Lti::ResourceLink.active.find_by(id: resource_link_id)).to be_nil
            expect(Assignment.active.find_by(id: assignment_id)).to be_nil
          end

          it "responds with no content" do
            send_request
            expect(response).to be_no_content
          end
        end
      end
    end
  end
end

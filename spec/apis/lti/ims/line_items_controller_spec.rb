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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')
require_dependency "lti/ims/line_items_controller"

module Lti
  module Ims
    RSpec.describe LineItemsController, type: :request do
      let(:course) { course_model }
      let(:resource_link) { resource_link_model(overrides: {resource_link_id: assignment.lti_context_id}) }
      let(:assignment) { assignment_model(course: course) }
      let(:parsed_response_body) { JSON.parse(response.body) }
      let(:label) { 'Originality Score' }
      let(:tag) { 'some_tag' }
      let(:resource_id) { 'orig-123' }
      let(:score_max) { 50 }
      let(:request_headers) { {} }

      let(:url) do
        Rails.application.routes.url_helpers.lti_line_item_edit_path(
          course_id: course.id,
          id: line_item.id
        )
      end

      shared_examples 'external tool check' do
        context 'when owned by the tool' do
          it 'is allowed to access'
        end

        context 'when not owned by the tool' do
          it 'is not allowed to access'
        end
      end

      describe '#create' do
        let(:line_item_create_params) do
          {
            scoreMaximum: score_max,
            label: label,
            resourceId: resource_id,
            tag: tag,
            ltiLinkId: assignment.lti_context_id
          }
        end

        let(:url) { Rails.application.routes.url_helpers.lti_line_item_create_path(course_id: course.id) }

        before do
          resource_link.line_items.create!(
            score_maximum: 1,
            label: 'Canvas Created',
            assignment: assignment
          )
        end

        it_behaves_like 'external tool check'

        shared_examples 'the line item create endpoint' do
          let(:create_params) { raise 'set in example' }

          it 'creates a new line' do
            expect do
              post url, params: create_params, headers: request_headers
            end.to change(Lti::LineItem, :count).by(1)
          end

          it 'responds with 404 if course is concluded' do
            course.update_attributes!(workflow_state: 'completed')
            post url, params: create_params, headers: request_headers
            expect(response).to be_not_found
          end

          it 'responds with the line item mime type' do
            post url, params: create_params, headers: request_headers
            expect(response.headers['Content-Type']).to include described_class::MIME_TYPE
          end
        end

        context 'when using the declarative model' do
          it_behaves_like 'the line item create endpoint' do
            let(:create_params) { line_item_create_params }
          end

          it 'properly formats the response' do
            post url, params: line_item_create_params, headers: request_headers
            item = Lti::LineItem.find(parsed_response_body['id'].split('/').last)

            expected_response = {
              id: "http://www.example.com/api/lti/courses/#{course.id}/line_items/#{item.id}",
              scoreMaximum: score_max.to_f,
              label: label,
              resourceId: resource_id,
              tag: tag,
              ltiLinkId: item.resource_link.resource_link_id
            }.with_indifferent_access

            expect(parsed_response_body).to eq expected_response
          end

          it 'associates the line item with the correct assignment' do
            post url, params: line_item_create_params, headers: request_headers
            body = parsed_response_body
            expect(Lti::LineItem.find(body['id'].split('/').last).assignment).to eq assignment
          end

          it 'associates the line item with the correct resource link' do
            post url, params: line_item_create_params, headers: request_headers
            body = parsed_response_body
            item = Lti::LineItem.find(body['id'].split('/').last)
            expect(item.resource_link).to eq resource_link
          end

          it 'does not create a new assignment' do
            assignment
            expect do
              post url, params: line_item_create_params, headers: request_headers
            end.not_to change(Assignment, :count)
          end

          it 'renders precondition failed if ResourceLink has no LineItems' do
            resource_link.line_items.destroy_all
            post url, params: line_item_create_params, headers: request_headers
            expect(response).to be_precondition_failed
          end

          it 'renders not found if no matching ResourceLink for the specified ltiLinkId' do
            post url,
                 params: line_item_create_params.merge(ltiLinkId: SecureRandom.uuid),
                 headers: request_headers
            expect(response).to be_not_found
          end

          it 'renders unauthorized if the tool is not associated with the requested resource link'
        end

        context 'when using the uncoupled model' do
          let(:uncoupled_line_item_params) { line_item_create_params.except(:ltiLinkId) }

          it_behaves_like 'the line item create endpoint' do
            let(:create_params) { uncoupled_line_item_params }
          end

          it 'properly formats the response' do
            post url, params: uncoupled_line_item_params, headers: request_headers
            item = Lti::LineItem.find(parsed_response_body['id'].split('/').last)

            expected_response = {
              id: "http://www.example.com/api/lti/courses/#{course.id}/line_items/#{item.id}",
              scoreMaximum: score_max.to_f,
              label: label,
              resourceId: resource_id,
              tag: tag
            }.with_indifferent_access

            expect(parsed_response_body).to eq expected_response
          end

          it 'creates a new assignment' do
            assignment
            expect do
              post url, params: uncoupled_line_item_params, headers: request_headers
            end.to change {Assignment.count}.by(1)
          end

          context 'when a new assignment is created' do
            before do
              post url, params: uncoupled_line_item_params, headers: request_headers
              body = parsed_response_body
              @item = Lti::LineItem.find(body['id'].split('/').last)
            end

            it 'sets the score maximum on the new assignment' do
              expect(@item.assignment.points_possible).to eq score_max
            end

            it 'sets the submission type on the new assignment' do
              expect(@item.assignment.submission_types).to eq 'none'
            end

            it 'sets the name for the assignment' do
              expect(@item.assignment.name).to eq label
            end

            it 'sets the context of the new assignment' do
              expect(@item.assignment.context).to eq course
            end
          end

          it 'renders unauthorized if the tool lacks the required permission to create line items'
        end
      end

      describe '#update' do
        let(:line_item) do
          line_item_model(
            assignment: assignment,
            resource_link: resource_link
          )
        end

        it_behaves_like 'external tool check'

        it 'updates the score maximum' do
          new_score_maximum = 88.2
          put url,
              params: {scoreMaximum: new_score_maximum},
              headers: request_headers
          body = parsed_response_body
          expect(body['scoreMaximum']).to eq new_score_maximum
        end

        it 'updates the label' do
          new_label = 'a new label!'
          put url,
              params: {label: new_label},
              headers: request_headers
          expect(line_item.reload.label).to eq new_label
        end

        it 'does not update the assignment name if not the default line item' do
          line_item_one = line_item_model(resource_link: resource_link, assignment: assignment)
          line_item_two = line_item_model(resource_link: resource_link, assignment: assignment)
          line_item_two.update_attributes!(created_at: line_item_one.created_at + 5.seconds)

          second_url = Rails.application.routes.url_helpers.lti_line_item_edit_path(
            course_id: course.id,
            id: line_item.id
          )

          original_name = assignment.name
          new_label = 'a new label!'
          put second_url,
              params: {label: new_label},
              headers: request_headers
          expect(line_item.reload.assignment.name).to eq original_name
        end

        it 'updates the assignment name if ResourceLink is absent' do
          line_item.update_attributes!(resource_link: nil)
          new_label = 'a new label!'
          put url,
              params: {label: new_label},
              headers: request_headers
          expect(line_item.reload.assignment.name).to eq new_label
        end

        it 'updates the assignment name if default line item' do
          new_label = 'a new label!'
          put url,
              params: {label: new_label},
              headers: request_headers
          expect(line_item.reload.assignment.name).to eq new_label
        end

        it 'updates the resourceId' do
          new_resource_id = 'resource-id'
          put url,
              params: {resourceId: new_resource_id},
              headers: request_headers
          body = parsed_response_body
          expect(body['resourceId']).to eq new_resource_id
        end

        it 'updates the tag' do
          new_tag = 'New Tag'
          put url,
              params: {tag: new_tag},
              headers: request_headers
          body = parsed_response_body
          expect(body['tag']).to eq new_tag
        end

        it 'responds with precondition failed message if a non-matching ltiLinkId is included' do
          new_assignment = assignment_model
          new_lti_link_id = new_assignment.lti_context_id
          resource_link_model(overrides: {resource_link_id: new_lti_link_id})
          put url,
              params: {ltiLinkId: new_lti_link_id},
              headers: request_headers
          expect(response).to be_precondition_failed
        end

        it 'includes an error message if a non-mataching ltiLinkId is included' do
          new_assignment = assignment_model
          new_lti_link_id = new_assignment.lti_context_id
          resource_link_model(overrides: {resource_link_id: new_lti_link_id})
          put url,
              params: {ltiLinkId: new_lti_link_id},
              headers: request_headers
          error_message = parsed_response_body.dig('errors', 'message')
          expect(error_message).to eq 'The specified LTI link ID is not associated with the line item.'
        end

        it 'correctly formats the requested line item' do
          put url, headers: request_headers

          expected_response = {
            id: "http://www.example.com/api/lti/courses/#{course.id}/line_items/#{line_item.id}",
            scoreMaximum: 10.0,
            label: 'Test Line Item',
            ltiLinkId: line_item.resource_link.resource_link_id
          }.with_indifferent_access

          expect(parsed_response_body).to eq expected_response
        end
      end

      describe '#show' do
        let!(:line_item) do
          line_item_model(
            assignment: assignment,
            resource_link: resource_link,
            tag: tag,
          )
        end

        it_behaves_like 'external tool check'

        it 'correctly formats the requested line item' do
          get url, headers: request_headers
          expected_response = {
            id: "http://www.example.com/api/lti/courses/#{course.id}/line_items/#{line_item.id}",
            scoreMaximum: 10.0,
            label: 'Test Line Item',
            tag: tag,
            ltiLinkId: line_item.resource_link.resource_link_id
          }.with_indifferent_access
          expect(parsed_response_body).to eq expected_response
        end

        it 'responds with 404 if the line item is not found in the course' do
          new_course = course_model

          new_url = Rails.application.routes.url_helpers.lti_line_item_edit_path(
            course_id: new_course.id,
            id: line_item.id
          )

          get new_url, headers: request_headers
          expect(response).to be_not_found
        end

        it 'responds with 404 if the line item does not exist' do
          new_line_item = line_item_model
          new_line_item.save!

          new_url = Rails.application.routes.url_helpers.lti_line_item_edit_path(
            course_id: course.id,
            id: new_line_item.id
          )

          get new_url, headers: request_headers
          expect(response).to be_not_found
        end

        it 'responds with 404 if the course does not exist' do
          new_url = Rails.application.routes.url_helpers.lti_line_item_edit_path(
            course_id: Course.last.id + 1,
            id: line_item.id
          )
          get new_url, headers: request_headers
          expect(response).to be_not_found
        end

        it 'responds with the line item mime type' do
          get url, headers: request_headers
          expect(response.headers['Content-Type']).to include described_class::MIME_TYPE
        end
      end

      describe '#index' do
        let(:url) do
          Rails.application.routes.url_helpers.lti_line_item_index_path(
            course_id: course.id,
          )
        end

        # The following "let!" declarations are used to provide a
        # diverse pool of line items when testing the queries in
        # the specs that follow.
        let!(:line_item) do
          line_item_model(
            assignment: assignment
          )
        end

        let!(:line_item_with_tag) do
          line_item_model(
            assignment: assignment,
            tag: tag
          )
        end

        let!(:line_item_with_resource_id) do
          line_item_model(
            assignment: assignment,
            resource_id: resource_id
          )
        end

        let!(:line_item_with_lti_link_id) do
          line_item_model(
            assignment: assignment,
            resource_link: resource_link
          )
        end

        let(:line_item_list) do
          parsed_response_body.map { |li| LineItem.find(li['id'].split('/').last) }
        end

        it_behaves_like 'external tool check'

        it 'responds with 404 if context does not exist' do
          bad_url = Rails.application.routes.url_helpers.lti_line_item_index_path(
            course_id: course.id + 50,
          )
          get bad_url, headers: request_headers
          expect(response).to be_not_found
        end

        it 'includes all associated line items in the course' do
          get url, headers: request_headers
          expect(line_item_list).to match_array([
            line_item,
            line_item_with_tag,
            line_item_with_resource_id,
            line_item_with_lti_link_id
          ])
        end

        it 'correctly queries by tag' do
          get url, params: {tag: tag}, headers: request_headers
          expect(line_item_list).to match_array([
            line_item_with_tag
          ])
        end

        it 'correctly queries by resource_id' do
          get url, params: {resource_id: resource_id}, headers: request_headers
          expect(line_item_list).to match_array([
            line_item_with_resource_id
          ])
        end

        it 'correctly queries by lti_link_id' do
          get url, params: {lti_link_id: resource_link.resource_link_id}, headers: request_headers
          expect(line_item_list).to match_array([
            line_item_with_lti_link_id
          ])
        end

        it 'allows querying by multiple valid fields at the same time' do
          tag_and_resource = line_item_model(
            assignment: assignment,
            tag: tag,
            resource_id: resource_id
          )
          get url, params: {tag: tag, resource_id: resource_id}, headers: request_headers
          expect(line_item_list).to match_array([
            tag_and_resource
          ])
        end

        it 'responds with the correct mime type' do
          get url, headers: request_headers
          expect(response.headers['Content-Type']).to include described_class::CONTAINER_MIME_TYPE
        end

        it 'includes pagination headers' do
          get url, headers: request_headers
          expect(response.headers.key?('Link')).to eq true
        end
      end

      describe 'destroy' do
        it_behaves_like 'external tool check'

        shared_examples 'the line item destroy endpoint' do
          let(:line_item) { raise 'override in spec' }

          it 'deletes the correct line item' do
            delete url, headers: request_headers
            expect(Lti::LineItem.find_by(id: line_item.id)).to be_nil
          end

          it 'responds with no content' do
            delete url, headers: request_headers
            expect(response).to be_no_content
          end
        end

        context 'when using the coupled model' do
          let(:coupled_line_item) do
            line_item_model(
              assignment: assignment,
              resource_link: resource_link,
              tag: tag,
              resource_id: resource_id
            )
          end

          let!(:second_line_item) do
            line_item_model(
              assignment: assignment,
              resource_link: resource_link,
              tag: tag,
              resource_id: resource_id
            )
          end

          it_behaves_like 'the line item destroy endpoint' do
            let(:line_item) do
              coupled_line_item
            end
          end

          it 'does not allow destroying default line items' do
            new_url = Rails.application.routes.url_helpers.lti_line_item_show_path(
              course_id: course.id,
              id: second_line_item.id
            )
            delete new_url, headers: request_headers
            expect(response).to be_unauthorized
          end
        end

        context 'when using the uncoupled model' do
          it_behaves_like 'the line item destroy endpoint' do
            let(:line_item) do
              line_item_model(
                assignment: assignment,
                tag: tag,
                resource_id: resource_id
              )
            end
          end
        end
      end
    end
  end
end

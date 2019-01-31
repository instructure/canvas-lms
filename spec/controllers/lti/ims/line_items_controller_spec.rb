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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/concerns/advantage_services_shared_context')
require File.expand_path(File.dirname(__FILE__) + '/concerns/advantage_services_shared_examples')
require_dependency "lti/ims/line_items_controller"

module Lti
  module Ims
    RSpec.describe LineItemsController do
      include_context 'advantage services context'

      let(:context) { course }
      let(:unknown_context_id) { (Course.maximum(:id) || 0) + 1 }
      let(:resource_link) do
        if tool.present? && tool.use_1_3?
          resource_link_model(overrides: {resource_link_id: assignment.lti_context_id})
        else
          resource_link_model
        end
      end
      let(:assignment) do
        opts = {course: course}
        if tool.present?
          opts[:submission_types] = 'external_tool'
          opts[:external_tool_tag_attributes] = {
            url: tool.url,
            content_type: 'context_external_tool',
            content_id: tool.id
          }
        end
        assignment_model(opts)
      end
      let(:parsed_response_body) { JSON.parse(response.body) }
      let(:label) { 'Originality Score' }
      let(:tag) { 'some_tag' }
      let(:resource_id) { 'orig-123' }
      let(:score_max) { 50 }
      let(:scope_to_remove) { 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem' }

      shared_examples 'assignment with wrong tool' do
        let(:other_tool) do
          ContextExternalTool.create!(
            context: tool_context,
            consumer_key: 'key',
            shared_secret: 'secret',
            name: 'wrong tool',
            url: 'http://www.wrong_tool.com/launch',
            developer_key: DeveloperKey.create!,
            settings: { use_1_3: true },
            workflow_state: 'public'
          )
        end
        let(:line_item) do
          line_item_model(
            course: course,
            with_resource_link: true,
            tool: other_tool
          )
        end

        it 'returns a precondition_failed' do
          send_request
          expect(response).to have_http_status :precondition_failed
        end
      end

      describe '#create' do
        let(:params_overrides) do
          {
            scoreMaximum: score_max,
            label: label,
            resourceId: resource_id,
            tag: tag,
            resourceLinkId: assignment.lti_context_id,
            course_id: context_id
          }
        end
        let(:action) { :create }
        let(:http_success_status) { :created }

        it_behaves_like 'advantage services'

        before do
          resource_link.context_external_tool.update!(developer_key: developer_key)
          resource_link.line_items.create!(
            score_maximum: 1,
            label: 'Canvas Created',
            assignment: assignment
          )
        end

        shared_examples 'the line item create endpoint' do
          it 'creates a new line' do
            expect do
              send_request
            end.to change(Lti::LineItem, :count).by(1)
          end

          it 'responds with 404 if course is concluded' do
            course.update_attributes!(workflow_state: 'completed')
            send_request
            expect(response).to be_not_found
          end

          it 'responds with the line item mime type' do
            send_request
            expect(response.headers['Content-Type']).to include described_class::MIME_TYPE
          end
        end

        context 'when using the declarative model' do
          it_behaves_like 'the line item create endpoint'

          it 'properly formats the response' do
            send_request
            item = Lti::LineItem.find(parsed_response_body['id'].split('/').last)

            expected_response = {
              id: "http://test.host/api/lti/courses/#{course.id}/line_items/#{item.id}",
              scoreMaximum: score_max.to_f,
              label: label,
              resourceId: resource_id,
              tag: tag,
              resourceLinkId: item.resource_link.resource_link_id
            }.with_indifferent_access

            expect(parsed_response_body).to eq expected_response
          end

          it 'associates the line item with the correct assignment' do
            send_request
            body = parsed_response_body
            expect(Lti::LineItem.find(body['id'].split('/').last).assignment).to eq assignment
          end

          it 'associates the line item with the correct resource link' do
            send_request
            body = parsed_response_body
            item = Lti::LineItem.find(body['id'].split('/').last)
            expect(item.resource_link).to eq resource_link
          end

          it 'does not create a new assignment' do
            assignment
            expect do
              send_request
            end.not_to change(Assignment, :count)
          end

          it 'renders precondition failed if ResourceLink has no LineItems' do
            resource_link.line_items.destroy_all
            send_request
            expect(response).to be_precondition_failed
          end

          context do
            let(:params_overrides) { super().merge(resourceLinkId: SecureRandom.uuid) }

            it 'renders not found if no matching ResourceLink for the specified resourceLinkId' do
              send_request
              expect(response).to be_not_found
            end
          end
        end

        context 'when using the uncoupled model' do
          let(:params_overrides) { super().except(:resourceLinkId) }

          it_behaves_like 'the line item create endpoint'

          it 'properly formats the response' do
            send_request
            item = Lti::LineItem.find(parsed_response_body['id'].split('/').last)

            expected_response = {
              id: "http://test.host/api/lti/courses/#{course.id}/line_items/#{item.id}",
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
              send_request
            end.to change {Assignment.count}.by(1)
          end

          it 'does not create a resource_link record' do
            expect do
              send_request
            end.to change {Lti::ResourceLink.count}.by(0)
          end

          context 'when a new assignment is created' do
            let(:item) { Lti::LineItem.find(parsed_response_body['id'].split('/').last) }

            before do
              send_request
            end

            it 'sets the score maximum on the new assignment' do
              expect(item.assignment.points_possible).to eq score_max
            end

            it 'sets the submission type on the new assignment' do
              expect(item.assignment.submission_types).to eq 'none'
            end

            it 'does not attach a resource_link' do
              expect(item.resource_link).to be_blank
            end

            it 'sets the name for the assignment' do
              expect(item.assignment.name).to eq label
            end

            it 'sets the context of the new assignment' do
              expect(item.assignment.context).to eq course
            end
          end
        end
      end

      describe '#update' do
        let(:line_item) do
          line_item_model(
            assignment: assignment,
            resource_link: resource_link
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

        it_behaves_like 'advantage services'
        it_behaves_like 'assignment with wrong tool'

        context do
          let(:new_score_maximum) { 88.2 }
          let(:params_overrides) { super().merge(scoreMaximum: new_score_maximum) }
          it 'updates the score maximum' do
            send_request
            body = parsed_response_body
            expect(body['scoreMaximum']).to eq new_score_maximum
          end
        end

        context do
          let(:new_label) { 'a new label!' }
          let(:params_overrides) { super().merge(label: new_label) }
          it 'updates the label' do
            send_request
            expect(line_item.reload.label).to eq new_label
          end
        end

        context do
          let(:line_item_two) do
            li = line_item_model(resource_link: resource_link, assignment: assignment)
            li.update_attributes!(created_at: line_item.created_at + 5.seconds)
            li
          end
          let(:line_item_id) { line_item_two.id }
          let(:new_label) { 'a new label!' }
          let(:params_overrides) { super().merge(label: new_label) }

          it 'does not update the assignment name if not the default line item' do
            original_name = assignment.name
            send_request
            expect(line_item.reload.assignment.name).to eq original_name
          end
        end

        context do
          let(:new_label) { 'a new label!' }
          let(:params_overrides) { super().merge(label: new_label) }
          let(:line_item) { assignment.line_items.first }

          it 'updates the assignment name if ResourceLink is absent' do
            line_item.update_attributes!(resource_link: nil)
            send_request
            expect(line_item.reload.assignment.name).to eq new_label
          end

          it 'updates the assignment name if default line item' do
            send_request
            expect(line_item.reload.assignment.name).to eq 'a new label!'
          end
        end

        context do
          let(:new_resource_id) { 'resource-id' }
          let(:params_overrides) { super().merge(resourceId: new_resource_id) }

          it 'updates the resourceId' do
            send_request
            body = parsed_response_body
            expect(body['resourceId']).to eq new_resource_id
          end
        end

        context do
          let(:new_tag) { 'New Tag' }
          let(:params_overrides) { super().merge(tag: new_tag) }

          it 'updates the tag' do
            send_request
            body = parsed_response_body
            expect(body['tag']).to eq new_tag
          end
        end

        context do
          let(:new_resource_link_id) do
            a = assignment_model
            a.lti_context_id
          end
          let(:params_overrides) { super().merge(resourceLinkId: new_resource_link_id) }

          it 'responds with precondition failed message if a non-matching resourceLinkId is included' do
            send_request
            expect(response).to be_precondition_failed
          end

          it 'includes an error message if a non-mataching resourceLinkId is included' do
            send_request
            error_message = parsed_response_body.dig('errors', 'message')
            expect(error_message).to eq 'The specified LTI link ID is not associated with the line item.'
          end
        end

        it 'correctly formats the requested line item' do
          send_request

          expected_response = {
            id: "http://test.host/api/lti/courses/#{course.id}/line_items/#{line_item.id}",
            scoreMaximum: 10.0,
            label: 'Test Line Item',
            resourceLinkId: line_item.resource_link.resource_link_id
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
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly'
          ]
        end

        it_behaves_like 'advantage services'
        it_behaves_like 'assignment with wrong tool'

        it 'correctly formats the requested line item' do
          send_request
          expected_response = {
            id: "http://test.host/api/lti/courses/#{course.id}/line_items/#{line_item.id}",
            scoreMaximum: 10.0,
            label: 'Test Line Item',
            tag: tag,
            resourceLinkId: line_item.resource_link.resource_link_id
          }.with_indifferent_access
          expect(parsed_response_body).to eq expected_response
        end

        context do
          let(:context_id) { course_model.id }

          it 'responds with 404 if the line item is not found in the course' do
            send_request
            expect(response).to be_not_found
          end
        end

        context do
          let(:line_item_id) {  Lti::LineItem.maximum(:id) + 1 }

          it 'responds with 404 if the line item does not exist' do
            send_request
            expect(response).to be_not_found
          end
        end

        context do
          let(:context_id) { Course.last.id + 1 }

          it 'responds with 404 if the course does not exist' do
            send_request
            expect(response).to be_not_found
          end
        end

        it 'responds with the line item mime type' do
          send_request
          expect(response.headers['Content-Type']).to include described_class::MIME_TYPE
        end
      end

      describe '#index' do
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
        let!(:line_item_with_resource_link_id) do
          line_item_model(
            assignment: assignment,
            resource_link: resource_link
          )
        end
        let(:line_item_list) do
          parsed_response_body.map { |li| LineItem.find(li['id'].split('/').last) }
        end
        let(:scope_to_remove) do
          [
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly'
          ]
        end
        let(:expected_mime_type) { described_class::CONTAINER_MIME_TYPE }

        it_behaves_like 'advantage services'

        context do
          let(:context_id) { Course.last.id + 1 }

          it 'responds with 404 if context does not exist' do
            send_request
            expect(response).to be_not_found
          end
        end

        it 'includes all associated line items in the course' do
          send_request
          expect(line_item_list).to match_array([
            line_item,
            line_item_with_tag,
            line_item_with_resource_id,
            line_item_with_resource_link_id
          ])
        end

        context do
          let(:params_overrides) { super().merge(tag: tag) }

          it 'correctly queries by tag' do
            send_request
            expect(line_item_list).to match_array([
              line_item_with_tag
            ])
          end
        end

        context do
          let(:params_overrides) { super().merge(resource_id: resource_id) }

          it 'correctly queries by resource_id' do
            send_request
            expect(line_item_list).to match_array([
              line_item_with_resource_id
            ])
          end
        end

        context do
          let(:line_item_new_lti_link) do
            line_item_model(
              course: course,
              with_resource_link: true,
              tool: tool
            )
          end
          let(:params_overrides) { super().merge(resource_link_id: line_item_new_lti_link.resource_link.resource_link_id) }

          it 'correctly queries by resource_link_id' do
            send_request
            expect(line_item_list).to match_array([
              line_item_new_lti_link.assignment.line_items.first,
              line_item_new_lti_link
            ])
          end
        end

        context do
          let(:params_overrides) { super().merge(tag: tag, resource_id: resource_id) }

          it 'allows querying by multiple valid fields at the same time' do
            tag_and_resource = line_item_model(
              assignment: assignment,
              tag: tag,
              resource_id: resource_id
            )
            send_request
            expect(line_item_list).to match_array([
              tag_and_resource
            ])
          end
        end

        it 'responds with the correct mime type' do
          send_request
          expect(response.headers['Content-Type']).to include described_class::CONTAINER_MIME_TYPE
        end

        it 'includes pagination headers' do
          send_request
          expect(response.headers.key?('Link')).to eq true
        end
      end

      describe 'destroy' do
        let(:line_item_id) { line_item.id }
        let(:params_overrides) do
          {
            course_id: context_id,
            id: line_item_id
          }
        end
        let(:action) { :destroy }

        shared_examples 'the line item destroy endpoint' do
          it_behaves_like 'assignment with wrong tool'

          it 'deletes the correct line item' do
            send_request
            expect(Lti::LineItem.find_by(id: line_item_id)).to be_nil
          end

          it 'responds with no content' do
            send_request
            expect(response).to be_no_content
          end
        end

        context 'when using the coupled model' do
          let(:coupled_line_item) do
            assignment.line_items.first.update!(
              tag: tag,
              resource_id: resource_id
            )
            assignment.line_items.first
          end

          let!(:second_line_item) do
            line_item_model(
              assignment: assignment,
              resource_link: resource_link,
              tag: tag,
              resource_id: resource_id
            )
          end
          let(:line_item) do
            second_line_item
          end

          it_behaves_like 'the line item destroy endpoint'

          context do
            let(:line_item) { coupled_line_item }

            it 'does not allow destroying default line items' do
              send_request
              expect(response).to be_unauthorized
            end
          end
        end

        xcontext 'when using the uncoupled model' do
          let(:line_item) do
            line_item_model(
              course: course,
              tag: tag,
              resource_id: resource_id
            )
          end

          it_behaves_like 'the line item destroy endpoint'
        end
      end
    end
  end
end

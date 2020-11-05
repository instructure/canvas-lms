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
#

require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper')
require_dependency "lti/ims/concerns/gradebook_services"

module Lti
  module Ims::Concerns
    describe GradebookServices, type: :controller do
      controller(ApplicationController) do
        include Lti::Ims::Concerns::GradebookServices
        before_action :prepare_line_item_for_ags!, :verify_user_in_context, :verify_line_item_in_context
        skip_before_action(
          :verify_access_token,
          :verify_developer_key,
          :verify_tool,
          :verify_active_in_account,
          :verify_access_scope
        )

        def index
          return render_error(params[:error_message]) if params.key?(:error_message)
          render json: output
        end

        private

        def output
          {
            line_item_id: line_item.id,
            context_id: context.id,
            user_id: user.id
          }
        end
      end

      let_once(:context) { course_model(workflow_state: 'available') }
      let_once(:user) { student_in_course(course: context).user }
      let_once(:assignment) do
        opts = {course: context}
        opts[:submission_types] = 'external_tool'
        opts[:external_tool_tag_attributes] = {
          url: tool.url,
          content_type: 'context_external_tool',
          content_id: tool.id
        }
        assignment_model(opts)
      end
      let_once(:developer_key) { DeveloperKey.create! }
      let_once(:tool) do
        ContextExternalTool.create!(
          context: context,
          consumer_key: 'key',
          shared_secret: 'secret',
          name: 'test tool',
          url: 'http://www.tool.com/launch',
          developer_key: developer_key,
          settings: { use_1_3: true },
          workflow_state: 'public'
        )
      end
      let_once(:line_item) { assignment.line_items.first }
      let(:parsed_response_body) { JSON.parse(response.body) }
      let(:valid_params) { {course_id: context.id, userId: user.id, line_item_id: line_item.id} }

      describe '#before_actions' do
        context 'with user and line item in context' do
          before { user.enrollments.first.update!(workflow_state: 'active') }

          it 'processes the request' do
            get :index, params: valid_params
            expect(response).to be_successful
          end
        end

        context 'with user not active in context' do
          it 'fails to process the request' do
            get :index, params: valid_params
            expect(response.code).to eq '422'
          end
        end

        context 'with user not in context' do
          before { user.enrollments.destroy_all }

          it 'fails to process the request' do
            get :index, params: valid_params
            expect(response.code).to eq '422'
          end
        end

        context 'with uuid that first digit matches user_id' do
          before { user.enrollments.first.update!(workflow_state: 'active') }
          let(:valid_params) { {course_id: context.id, user_id: "#{user.id}apzx", line_item_id: line_item.id} }

          it 'fails to find user' do
            get :index, params: valid_params
            expect(response.code).to eq '422'
            expect(JSON.parse(response.body)['errors']['message']).to eq('User not found in course or is not a student')
          end
        end

        context 'when line item does not exist' do
          before { user.enrollments.first.update!(workflow_state: 'active') }

          it 'fails to process the request' do
            get :index, params: {course_id: context.id, userId: user.id, line_item_id: LineItem.last.id + 1}
            expect(response).to be_not_found
          end
        end
      end

      describe '#prepare_line_item_for_ags!' do
        before do
          allow(controller).to receive(:developer_key).and_return(developer_key)
        end

        context 'when resource link id is missing' do
          let(:valid_params) { {course_id: context.id, userId: user.id, line_item_id: line_item.id} }

          it 'is ignored' do
            expect_any_instance_of(Assignment).not_to receive(:prepare_for_ags_if_needed!)
            get :index, params: valid_params
          end
        end

        context 'when resource link id points to wrong assignment' do
          let(:valid_params) {
            a2 = assignment.clone
            a2.lti_context_id = nil
            a2.save
            {course_id: context.id, userId: user.id, resourceLinkId: a2.lti_context_id}
          }

          it 'fails to match assignment tool' do
            get :index, params: valid_params
            expect(response.code).to eq '422'
            expect(parsed_response_body['errors']['message']).to eq('Resource link id points to Tool not associated with this Context')
          end
        end

        context 'with correct resource link id' do
          let(:valid_params) { {course_id: context.id, userId: user.id, resourceLinkId: assignment.lti_context_id} }

          it 'fixes up line items on assignment' do
            expect_any_instance_of(Assignment).to receive(:prepare_for_ags_if_needed!)
            get :index, params: valid_params
          end
        end
      end
    end
  end
end

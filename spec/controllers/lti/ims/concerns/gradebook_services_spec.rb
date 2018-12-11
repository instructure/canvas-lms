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
        before_action :verify_user_in_context, :verify_line_item_in_context
        skip_before_action(
          :verify_access_token,
          :verify_developer_key,
          :verify_tool,
          :verify_tool_permissions,
          :verify_tool_features
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
      let_once(:assignment) { assignment_model context: context }
      let_once(:line_item) { line_item_model assignment: assignment }
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

        context 'when line item does not exist' do
          before { user.enrollments.first.update!(workflow_state: 'active') }

          it 'fails to process the request' do
            get :index, params: {course_id: context.id, userId: user.id, line_item_id: LineItem.last.id + 1}
            expect(response).to be_not_found
          end
        end
      end
    end
  end
end

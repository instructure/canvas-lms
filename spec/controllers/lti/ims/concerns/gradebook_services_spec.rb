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
        before_action :verify_user_in_context, :verify_line_item_in_context, only: [:show]

        def test_filter
          render json: [output]
        end

        def test_verification
          render json: output
        end

        def show_error
          render_error('Test message', :bad_request)
        end

        private

        def output
          {
            line_item_id: line_item.id,
            context_id: context.id,
            tool_id: tool.id,
            user_id: user.id
          }
        end
      end

      let_once(:context) { course_model }
      let_once(:user) { student_in_course(course: context).user }
      let_once(:assignment) { assignment_model context: context }
      let_once(:line_item) { line_item_model assignment: assignment }
      let(:parsed_response_body) { JSON.parse(response.body) }

      describe '#before_actions' do
        xit 'populates the resource helper methods correctly' do
          get :test_filter
          expect(parsed_response_body).to eq(
            {
              line_item_id: line_item.id,
              context_id: context.id,
              tool_id: tool.id,
              user_id: user.id
            }
          )
        end

        context 'with tool in context' do
          it 'allows access'
        end

        context 'with tool in context chain' do
          it 'allows access'
        end

        context 'with tool not in context' do
          it 'does not allow access'
        end

        context 'with tool that has capability' do
          it 'allows access'
        end

        context 'with tool that does not have capability' do
          it 'does not allow access'
        end

        context 'with user in context' do
          it 'processes the request'
        end

        context 'with user not in context' do
          it 'fails to process the request'
        end

        context 'with line_item in context' do
          it 'processes the request'
        end

        context 'with user not in context' do
          it 'fails to process the request'
        end
      end

      describe '#render_error' do
        it 'returns the error message and response correctly'
      end
    end
  end
end

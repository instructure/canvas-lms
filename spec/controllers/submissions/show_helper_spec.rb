# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'Submissions::ShowHelper' do
  describe 'included in a controller', type: :controller do
    controller do
      include Submissions::ShowHelper

      def show
        @context = Course.find(params[:context_id])
        @assignment = Assignment.find(params[:assignment_id])
        render_user_not_found
      end
    end

    describe '#render_user_not_found' do
      before do
        course_factory
        assignment_model
        routes.draw { get 'anonymous' => 'anonymous#show' }
      end

      context 'with format html' do
        before do
          get :show, context_id: @course.id, assignment_id: @assignment.id
        end

        it 'redirects to assignment url' do
          expect(response).to redirect_to(course_assignment_url(@course, @assignment.id))
        end

        it 'set flash error' do
          expect(flash[:error]).to be_present
        end
      end

      context 'with format json' do
        before do
          get :show, context_id: @course.id, assignment_id: @assignment.id, format: :json
        end

        it 'render json with errors key' do
          json = JSON.parse(response.body)
          expect(json.key?('errors')).to be_truthy
        end
      end
    end
  end
end

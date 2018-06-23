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

require_relative '../../spec_helper'

RSpec.describe Submissions::AnonymousPreviewsController do
  describe 'GET :show' do
    before do
      course_with_student_and_submitted_homework
      @context = @course
      user_session(@student)
    end

    it "renders show_preview" do
      get :show, params: {course_id: @context.id, assignment_id: @assignment.id, anonymous_id: @submission.anonymous_id, preview: true}
      expect(response).to render_template(:show_preview)
    end
  end
end

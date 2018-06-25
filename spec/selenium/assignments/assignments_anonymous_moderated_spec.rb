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

require_relative '../common'
require_relative 'page_objects/assignment_page'

describe 'Anonymous Moderated Marking' do
  include_context 'in-process server selenium tests'

  before(:each) do
    # create a course with a teacher
    course_with_teacher(course_name: 'Course1')
  end

  context 'with Anonymous Marking Flag' do
    it 'Anonymous Grading option is displayed if Anonymous Marking Flag is ON', priority: '1', test_id: 3496269 do
      Account.default.enable_feature!(:anonymous_marking)
      user_session(@teacher)
      AssignmentPage.visit_new_assignment_create_page(@course.id)

      expect(AssignmentPage.assignment_form).to contain_css '#enable-anonymous-grading'
    end

    it 'Anonymous Grading option is hidden if Anonymous Marking Flag is OFF' do # test_id: 3496269
      Account.default.disable_feature!(:anonymous_marking)
      user_session(@teacher)
      AssignmentPage.visit_new_assignment_create_page(@course.id)

      expect(AssignmentPage.assignment_form).not_to contain_css '#enable-anonymous-grading'
    end
  end

  context 'with Moderated Marking Flag' do
    it 'Moderated Grading option is displayed if Moderated Marking Flag is ON', priority: '1', test_id: 3496270 do
      Account.default.enable_feature!(:moderated_grading)
      user_session(@teacher)
      AssignmentPage.visit_new_assignment_create_page(@course.id)

      expect(AssignmentPage.assignment_form).to contain_css '.ModeratedGrading__Container'
    end

    it 'Moderated Grading option is hidden if Moderated Marking Flag is OFF' do # test_id: 3496270
      Account.default.disable_feature!(:moderated_grading)
      user_session(@teacher)
      AssignmentPage.visit_new_assignment_create_page(@course.id)

      expect(AssignmentPage.assignment_form).not_to contain_css '.ModeratedGrading__Container'
    end
  end
end


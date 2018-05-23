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

require_relative '../../common'
require_relative '../../assignments/page_objects/assignment_page'
require_relative '../pages/moderate_page'

describe 'Moderated Marking' do
  include_context 'in-process server selenium tests'

  before(:each) do
    Account.default.enable_feature!(:anonymous_moderated_marking)
    Account.default.enable_feature!(:moderated_grading)

    # create a course with two teachers
    @moderated_course = create_course(course_name: 'moderated_course', active_all: true)
    @teacher1 = User.create!(name: 'Teacher1')
    @teacher1.register!
    @moderated_course.enroll_teacher(@teacher1, enrollment_state: 'active')
    @teacher2 = User.create!(name: 'Teacher2')
    @teacher2.register!
    @moderated_course.enroll_teacher(@teacher2, enrollment_state: 'active')

    # create moderated assignment
    @moderated_assignment = @moderated_course.assignments.create!(
      title: 'Moderated Assignment1',
      grader_count: 2,
      grading_type: 'points',
      points_possible: 15,
      submission_types: 'online_upload',
      moderated_grading: true
    )

    # make Teacher1 the Final-Grader/Moderator for Assignment1
    @moderated_assignment.final_grader_id = @teacher1.id
    @moderated_assignment.save!
  end

  context 'with a final grader in a moderated assignment' do
    it 'moderate option is visible for final-grader', priority: '1', test_id: 3490527 do
      user_session(@teacher1)
      AssignmentPage.visit(@moderated_course.id, @moderated_assignment.id)

      expect(AssignmentPage.assignment_content).to contain_css('#moderated_grading_button')
    end

    it 'non-final-grader cannot navigate to moderation page', priority: '1', test_id: 3490530 do
      user_session(@teacher2)
      ModeratePage.visit(@moderated_course.id, @moderated_assignment.id)

      expect(ModeratePage.main_content_area).to contain_css('#unauthorized_message')
    end
  end

  context 'with Select_Final_Grade permission' do
    before(:each) do
      # enroll a ta and remove permission for TA role
      @ta1 = User.create!(name: 'TA_One')
      @ta1.register!
      @moderated_course.enroll_ta(@ta1, enrollment_state: 'active')
      Account.default.role_overrides.create!(role: Role.find_by(name: 'TaEnrollment'), permission: 'select_final_grade', enabled: false)

      user_session(@teacher1)
      AssignmentPage.visit_assignment_edit_page(@moderated_course.id, @moderated_assignment.id)
    end

    it 'user without the permission is not displayed in final grader dropdown', priority: '1', test_id: 3490529 do
      AssignmentPage.select_grader_dropdown.click

      expect(AssignmentPage.select_grader_dropdown).not_to include_text(@ta1.name)
    end
  end
end

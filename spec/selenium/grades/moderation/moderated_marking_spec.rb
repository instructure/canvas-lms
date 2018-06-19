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
require_relative '../pages/gradebook_page'

describe 'Moderated Marking' do
  include_context 'in-process server selenium tests'

  before(:once) do
    Account.default.enable_feature!(:moderated_grading)

    # create a course with three teachers
    @moderated_course = create_course(course_name: 'moderated_course', active_all: true)
    @teacher1 = User.create!(name: 'Teacher1')
    @teacher1.register!
    @moderated_course.enroll_teacher(@teacher1, enrollment_state: 'active')
    @teacher2 = User.create!(name: 'Teacher2')
    @teacher2.register!
    @moderated_course.enroll_teacher(@teacher2, enrollment_state: 'active')
    @teacher3 = User.create!(name: 'Teacher3')
    @teacher3.register!
    @moderated_course.enroll_teacher(@teacher3, enrollment_state: 'active')
    # enroll two students
    @student1 = User.create!(name: 'Some Student')
    @student1.register!
    @moderated_course.enroll_student(@student1, enrollment_state: 'active')

    @student2 = User.create!(name: 'Some Other Student')
    @student2.register!
    @moderated_course.enroll_student(@student2, enrollment_state: 'active')

    # create moderated assignment
    @moderated_assignment = @moderated_course.assignments.create!(
      title: 'Moderated Assignment1',
      grader_count: 2,
      final_grader_id: @teacher1.id,
      grading_type: 'points',
      points_possible: 15,
      submission_types: 'online_text_entry',
      moderated_grading: true
    )
  end

  context 'with a final-grader in a moderated assignment' do
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

    it 'user without the permission is not displayed in final-grader dropdown', priority: '1', test_id: 3490529 do
      AssignmentPage.select_grader_dropdown.click

      expect(AssignmentPage.select_grader_dropdown).not_to include_text(@ta1.name)
    end
  end

  context 'with max grader count reached' do
    before(:once) do

      # grader-count = 1, final_grader = Teacher1
      @moderated_assignment.update(grader_count: 1)

      # give a grade as non-final grader
      @student1_submission = @moderated_assignment.submit_homework(@student1, :body => 'student 1 submission moderated assignment')
      @student1_submission = @moderated_assignment.grade_student(@student1, grade: 13, grader: @teacher3, provisional: true).first
    end

    it 'final-grader can access speedgrader', priority: '1', test_id: 3496271 do
      user_session(@teacher1)
      AssignmentPage.visit(@moderated_course.id, @moderated_assignment.id)

      expect(AssignmentPage.page_action_list.text).to include 'SpeedGrader™'
    end

    it 'speedgrader link not visible to non-final-grader' do # test_id: 3496271
      user_session(@teacher2)
      AssignmentPage.visit(@moderated_course.id, @moderated_assignment.id)

      expect(AssignmentPage.page_action_list.text).not_to include 'SpeedGrader™'
    end

    it 'informs user that maximum number of grades has been reached for the submission' do # test_id: 3496271
      user_session(@teacher2)
      get "/courses/#{@moderated_course.id}/gradebook/speed_grader?assignment_id=#{@moderated_assignment.id}"
      wait_for_ajaximations

      expect_flash_message :success, 'The maximum number of graders for this assignment has been reached.'
    end
  end

  context 'moderation page' do
    before(:once) do
      # update the grader count
      @moderated_assignment.update(grader_count: 2)

      # grade both students provisionally with teacher 2
      @moderated_assignment.grade_student(@student1, grade: 15, grader: @teacher2, provisional: true)
      @moderated_assignment.grade_student(@student2, grade: 14, grader: @teacher2, provisional: true)

      # grade both students provisionally with teacher 3
      @moderated_assignment.grade_student(@student1, grade: 13, grader: @teacher3, provisional: true)
      @moderated_assignment.grade_student(@student2, grade: 12, grader: @teacher3, provisional: true)
    end

    it 'allows viewing provisional grades', priority: '1', test_id: 3503385 do
      # visit the moderation page as teacher 1
      user_session(@teacher1)
      ModeratePage.visit(@moderated_course.id, @moderated_assignment.id)

      # expect to see two students with two provisional grades
      expect(ModeratePage.fetch_student_count).to eq 2
      expect(ModeratePage.fetch_provisional_grade_count_for_student(@student1)).to eq 2
      expect(ModeratePage.fetch_provisional_grade_count_for_student(@student2)).to eq 2
    end

    it 'allows viewing provisional grades and posting final grade', priority: '1', test_id: 3503385 do
      # visit the moderation page as teacher 1
      user_session(@teacher1)
      ModeratePage.visit(@moderated_course.id, @moderated_assignment.id)

      # # select a provisional grade for each student
      ModeratePage.select_provisional_grade_for_student_by_position(@student1, 1)
      ModeratePage.select_provisional_grade_for_student_by_position(@student2, 2)

      # # post the grades
      ModeratePage.click_post_grades_button
      driver.switch_to.alert.accept
      wait_for_ajaximations

      # go to gradebook
      Gradebook::MultipleGradingPeriods.visit_gradebook(@moderated_course)

      # expect grades to be shown
      expect(Gradebook::MultipleGradingPeriods.grading_cell_attributes(0, 0).text).to eq('15')
      expect(Gradebook::MultipleGradingPeriods.grading_cell_attributes(0, 1).text).to eq('12')
    end

    it 'shows student names in row headers', priority: '1', test_id: 3503464 do
      # visit the moderation page as teacher 1
      user_session(@teacher1)
      ModeratePage.visit(@moderated_course.id, @moderated_assignment.id)

      # expect student names to be shown
      student_names = ModeratePage.student_table_row_headers.map(&:text)
      expect(student_names).to eql ['Some Student', 'Some Other Student']
    end

    it 'anonymizes students if anonymous grading is enabled', priority: '1', test_id: 3503464 do
      # enable anonymous grading
      @moderated_assignment.update(anonymous_grading: true)

      # visit the moderation page as teacher 1
      user_session(@teacher1)
      ModeratePage.visit(@moderated_course.id, @moderated_assignment.id)

      # expect student names to be replaced with anonymous stand ins
      student_names = ModeratePage.student_table_row_headers.map(&:text)
      expect(student_names).to eql ['Student 1', 'Student 2']
    end

    it 'shows grader names in table headers', priority: '1', test_id: 3503464 do
      # visit the moderation page as teacher 1
      user_session(@teacher1)
      ModeratePage.visit(@moderated_course.id, @moderated_assignment.id)

      # expect teacher names to be shown
      grader_names = ModeratePage.student_table_headers.map(&:text)
      expect(grader_names).to eql ['Teacher2', 'Teacher3']
    end

    it 'anonymizes graders if grader names visible to final grader is false', priority: '1', test_id: 3503464 do
      # disable grader names visible to final grader
      @moderated_assignment.update(grader_names_visible_to_final_grader: false)

      # visit the moderation page as teacher 1
      user_session(@teacher1)
      ModeratePage.visit(@moderated_course.id, @moderated_assignment.id)

      # expect teacher names to be replaced with anonymous stand ins
      grader_names = ModeratePage.student_table_headers.map(&:text)
      expect(grader_names).to eql ['Grader 1', 'Grader 2']
    end

    context 'when a custom grade is entered' do
      before(:each) do
        user_session(@teacher1)
        ModeratePage.visit(@moderated_course.id, @moderated_assignment.id)
        ModeratePage.enter_custom_grade(@student1, 4)
      end
      it 'selects the custom grade', priority: '1', test_id: 3505170 do
        # the aria-activedescendant will be the id of the selected option
        selected_id = ModeratePage.grade_input(@student1).attribute("aria-activedescendant")
        ModeratePage.grade_input(@student1).click
        expect(f("##{selected_id}").text).to eq "4 (Custom)"
      end
      it 'adds the custom grade as an option in the dropdown', priority: '1', test_id: 3505170 do
        ModeratePage.grade_input(@student1).click
        expect(ModeratePage.grade_input_dropdown(@student1)).to include_text "4 (Custom)"
      end
    end
  end
end

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
require_relative '../pages/student_grades_page'

describe 'Moderated Marking' do
  include_context 'in-process server selenium tests'

  before(:once) do
    Account.default.enable_feature!(:moderated_grading)

    # create a course with three teachers
    @moderated_course = course_factory(course_name: 'moderated_course', active_course: true)
    @teachers = create_users_in_course(@moderated_course, 3, return_type: :record, name_prefix: "TeacherBoss", enrollment_type: 'TeacherEnrollment')
    @teacher1 = @teachers[0]
    @teacher2 = @teachers[1]
    @teacher3 = @teachers[2]

    # enroll two students
    @students = create_users_in_course(@moderated_course, 2, return_type: :record, name_prefix: "Some Student")
    @student1 = @students[0]
    @student2 = @students[1]

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
      ta_in_course(course: @moderated_course, name: 'TA_One', enrollment_state: 'active')
      Account.default.role_overrides.create!(role: Role.find_by(name: 'TaEnrollment'), permission: 'select_final_grade', enabled: false)

      user_session(@teacher1)
      AssignmentPage.visit_assignment_edit_page(@moderated_course.id, @moderated_assignment.id)
    end

    it 'user without the permission is not displayed in final-grader dropdown', priority: '1', test_id: 3490529 do
      AssignmentPage.select_grader_dropdown.click

      expect(AssignmentPage.select_grader_dropdown).not_to include_text(@ta.name)
    end
  end

  context 'with max grader count reached' do
    before(:once) do

      # grader-count = 1, final_grader = Teacher1
      @moderated_assignment.update(grader_count: 1)

      # give a grade as non-final grader
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

    before(:each) do
      # visit the moderation page as teacher 1
      user_session(@teacher1)
      ModeratePage.visit(@moderated_course.id, @moderated_assignment.id)
    end

    it 'allows viewing provisional grades and posting final grade', priority: '1', test_id: 3503385 do
      # # select a provisional grade for each student
      ModeratePage.select_provisional_grade_for_student_by_position(@student1, 1)
      ModeratePage.select_provisional_grade_for_student_by_position(@student2, 2)

      # # post the grades
      ModeratePage.click_post_grades_button
      driver.switch_to.alert.accept
      wait_for_ajaximations

      # go to gradebook
      Gradebook.visit_gradebook(@moderated_course)

      # expect grades to be shown
      expect(Gradebook.grading_cell_attributes(0, 0).text).to eq('15')
      expect(Gradebook.grading_cell_attributes(0, 1).text).to eq('12')
    end

    it 'display to student allows viewing final grade as student', priority: '1', test_id: 3513992 do
      # select a provisional grade for each student
      ModeratePage.select_provisional_grade_for_student_by_position(@student1, 1)
      ModeratePage.select_provisional_grade_for_student_by_position(@student2, 2)

      # post the grades
      ModeratePage.click_post_grades_button
      driver.switch_to.alert.accept
      wait_for_ajaximations
      # wait for element to exist, means page has loaded
      ModeratePage.grades_posted_button

      # unmute using Display to Students button
      ModeratePage.click_display_to_students_button
      driver.switch_to.alert.accept
      wait_for_ajaximations
      # wait for element to exist, means page has loaded
      ModeratePage.grades_posted_button

      # switch session to student
      user_session(@student1)

      StudentGradesPage.visit_as_student(@moderated_course)
      expect(StudentGradesPage.fetch_assignment_score(@moderated_assignment)).to eq '15'
    end

    it 'displays comments from chosen grader', priority: "1", test_id: 3513994 do
      skip('Unskip in GRADE-1326')
      submissions = @moderated_assignment.find_or_create_submissions([@student1, @student2])

      submissions.each do |submission|
        submission.add_comment(author: @teacher1, comment: 'Just a comment by teacher1')
        submission.add_comment(author: @teacher2, comment: 'Just a comment by teacher2')
      end

      # select a provisional grade for each student
      ModeratePage.select_provisional_grade_for_student_by_position(@student1, 1)
      ModeratePage.select_provisional_grade_for_student_by_position(@student2, 2)

      # post the grades
      ModeratePage.click_post_grades_button
      driver.switch_to.alert.accept
      wait_for_ajaximations
      # wait for element to exist, means page has loaded
      ModeratePage.grades_posted_button

      # unmute using Display to Students button
      ModeratePage.click_display_to_students_button
      driver.switch_to.alert.accept
      wait_for_ajaximations
      # wait for element to exist, means page has loaded
      ModeratePage.grades_visible_to_students_button

      # switch session to student
      user_session(@student1)

      StudentGradesPage.visit_as_student(@moderated_course)
      StudentGradesPage.comment_button.click

      expect(StudentGradesPage.comments(@moderated_assignment).count).to eq 1
      expect(StudentGradesPage.comments(@moderated_assignment).first).to include_text 'Just a comment by teacher1'
    end

    it 'display to students button disabled until grades are posted', priority: '1', test_id: 3513991 do
      expect(ModeratePage.display_to_students_button).to be_disabled
    end

    it 'allows viewing provisional grades', priority: '1', test_id: 3503385 do
      # expect to see two students with two provisional grades
      expect(ModeratePage.fetch_student_count).to eq 2
      expect(ModeratePage.fetch_provisional_grade_count_for_student(@student1)).to eq 2
      expect(ModeratePage.fetch_provisional_grade_count_for_student(@student2)).to eq 2
    end

    it 'shows student names in row headers', priority: '1', test_id: 3503464 do
      # expect student names to be shown
      student_names = ModeratePage.student_table_row_headers.map(&:text)
      expect(student_names).to eql [@student1.name, @student2.name]
    end

    it 'anonymizes students if anonymous grading is enabled', priority: '1', test_id: 3503464 do
      # enable anonymous grading
      @moderated_assignment.update(anonymous_grading: true)
      refresh_page

      # expect student names to be replaced with anonymous stand ins
      student_names = ModeratePage.student_table_row_headers.map(&:text)
      expect(student_names).to eql ['Student 1', 'Student 2']
    end

    it 'shows grader names in table headers', priority: '1', test_id: 3503464 do
      # expect teacher names to be shown
      grader_names = ModeratePage.student_table_headers.map(&:text)
      expect(grader_names).to eql [@teacher2.name, @teacher3.name]
    end

    it 'anonymizes graders if grader names visible to final grader is false', priority: '1', test_id: 3503464 do
      # disable grader names visible to final grader
      @moderated_assignment.update(grader_names_visible_to_final_grader: false)
      refresh_page

      # expect teacher names to be replaced with anonymous stand ins
      grader_names = ModeratePage.student_table_headers.map(&:text)
      expect(grader_names).to eql ['Grader 1', 'Grader 2']
    end

    context 'when a custom grade is entered' do
      before(:each) do
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

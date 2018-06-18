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

require_relative "../../common"
require_relative "../../helpers/speed_grader_common"
require_relative "../pages/speedgrader_page"

describe "SpeedGrader" do
  include_context "in-process server selenium tests"
  include SpeedGraderCommon

  before(:each) do
    # a course with 1 teacher
    course_with_teacher_logged_in

    # enroll two students
    @student1 = User.create!(name: 'Student1')
    @student1.register!
    @course.enroll_student(@student1, enrollment_state: 'active')

    @student2 = User.create!(name: 'Student2')
    @student2.register!
    @course.enroll_student(@student2, enrollment_state: 'active')
  end

  context "with an anonymous assignment" do
    before(:each) do
      # an anonymous assignment
      @assignment = @course.assignments.create!(
        name: 'anonymous assignment',
        points_possible: 10,
        submission_types: 'text',
        anonymous_grading: true
      )

      user_session(@teacher)
      Speedgrader.visit(@course.id, @assignment.id)
    end

    it "student names are anonymous", priority: "1", test_id: 3481048 do
      Speedgrader.students_dropdown_button.click
      student_names = Speedgrader.students_select_menu_list.map(&:text)
      expect(student_names).to eql ['Student 1', 'Student 2']
    end

    context "given a specific student" do
      before do
        Speedgrader.click_next_or_prev_student(:next)
        Speedgrader.students_dropdown_button.click
        @current_student = Speedgrader.selected_student
      end

      it "when their submission is selected and page reloaded", priority: "1", test_id: 3481049 do
        expect { refresh_page }.not_to change { Speedgrader.selected_student.text }.from('Student 2')
      end
    end
  end

  context 'with a moderated assignment' do
    before(:each) do
      @teacher1 = @teacher
      @teacher2 = course_with_teacher(course: @course, name: 'Teacher2', active_all: true).user
      @teacher3 = course_with_teacher(course: @course, name: 'Teacher3', active_all: true).user

      @moderated_assignment = @course.assignments.create!(
        title: 'Moderated Assignment1',
        grader_count: 2,
        final_grader_id: @teacher1.id,
        grading_type: 'points',
        points_possible: 15,
        submission_types: 'online_text_entry',
        moderated_grading: true
      )
    end

    it 'prevents unmuting the assignment before grades are posted', priority: '2', test_id: 3493531 do
      user_session(@teacher2)
      Speedgrader.visit(@course.id, @moderated_assignment.id)

      expect(Speedgrader.mute_button.attribute('data-muted')).to eq 'true'
      expect(Speedgrader.mute_button.attribute('class')).to include 'disabled'
    end

    it 'allows unmuting the assignment after grades are posted', priority: '2', test_id: 3493531 do
      user_session(@teacher2)
      @moderated_assignment.update!(grades_published_at: Time.zone.now)
      Speedgrader.visit(@course.id, @moderated_assignment.id)

      expect(Speedgrader.mute_button.attribute('class')).not_to include 'disabled'
    end

    it 'allows adding provisional grades', priority: '2', test_id: 3505172 do
      user_session(@teacher2)
      Speedgrader.visit(@course.id, @moderated_assignment.id)
      Speedgrader.enter_grade(10)
      wait_for_ajaximations
      expect(@moderated_assignment.provisional_grades.first.scorer_id).to eq @teacher2.id
    end

    it 'shows multiple provisional grades', priority: '2', test_id: 3505172 do
      @moderated_assignment.grade_student(@student1, grade: '2', grader: @teacher2, provisional: true)
      @moderated_assignment.grade_student(@student1, grade: '3', grader: @teacher3, provisional: true)

      user_session(@teacher1)
      Speedgrader.visit(@course.id, @moderated_assignment.id)
      Speedgrader.show_details_button.click
      expect(Speedgrader.provisional_grade_radio_buttons.length).to eq 3
      expect(Speedgrader.grading_details_container.text).to include 'Custom'
      expect(Speedgrader.grading_details_container.text).to include 'Teacher2'
      expect(Speedgrader.grading_details_container.text).to include 'Teacher3'
    end

    it 'allows selecting a custom grade', priority: '1', test_id: 3505172 do
      @moderated_assignment.grade_student(@student1, grade: '2', grader: @teacher2, provisional: true)
      @moderated_assignment.grade_student(@student1, grade: '3', grader: @teacher3, provisional: true)

      user_session(@teacher1)
      Speedgrader.visit(@course.id, @moderated_assignment.id)
      Speedgrader.show_details_button.click
      Speedgrader.select_provisional_grade_by_label('Custom')
      Speedgrader.enter_grade(12)
      wait_for_ajaximations

      pg = @moderated_assignment.provisional_grades.last
      selections = @moderated_assignment.moderated_grading_selections

      expect(pg.score).to eq 12
      expect(selections.exists?(selected_provisional_grade_id: pg.id)).to be true
    end
  end

  context 'with a moderated anonymous assignment' do
    before(:each) do
      @teacher1 = @teacher
      @teacher2 = course_with_teacher(course: @course, name: 'Teacher2', active_all: true).user
      @teacher3 = course_with_teacher(course: @course, name: 'Teacher3', active_all: true).user

      @moderated_anonymous_assignment = @course.assignments.create!(
        title: 'Moderated Anonymous Assignment1',
        grader_count: 2,
        final_grader_id: @teacher1.id,
        moderated_grading: true,
        grader_comments_visible_to_graders: true,
        anonymous_grading: true,
        graders_anonymous_to_graders: true,
        grader_names_visible_to_final_grader: false
      )
    end

    it 'anonymizes grader comments', priority: '1', test_id: 3505165 do
      skip 'fixed with GRADE-1126'

      user_session(@teacher2)
      Speedgrader.visit(@course.id, @moderated_anonymous_assignment.id)

      Speedgrader.enter_grade(15)
      Speedgrader.add_comment_and_submit('Some comment text')
      wait_for_ajaximations

      user_session(@teacher3)
      Speedgrader.visit(@course.id, @moderated_anonymous_assignment.id)

      expect(Speedgrader.comments.length).to eq 1
      comment_text = Speedgrader.comments.first.text
      expect(comment_text).to include 'Some comment text'
      expect(comment_text).not_to include 'Teacher2'
      expect(comment_text).to include 'Grader 1'
    end

    it 'anonymizes graders for provisional grades', priority: '2', test_id: 3505172 do
      @moderated_anonymous_assignment.grade_student(@student1, grade: '2', grader: @teacher2, provisional: true)
      @moderated_anonymous_assignment.grade_student(@student1, grade: '3', grader: @teacher3, provisional: true)

      @moderated_anonymous_assignment.grade_student(@student2, grade: '2', grader: @teacher2, provisional: true)
      @moderated_anonymous_assignment.grade_student(@student2, grade: '3', grader: @teacher3, provisional: true)

      user_session(@teacher1)
      Speedgrader.visit(@course.id, @moderated_anonymous_assignment.id)
      Speedgrader.show_details_button.click

      expect(Speedgrader.grading_details_container.text).to include 'Grader 1'
      expect(Speedgrader.grading_details_container.text).to include 'Grader 2'
    end
  end
end

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
      # enroll a second teacher
      @teacher2 = User.create!(name: 'Teacher2')
      @teacher2.register!
      @course.enroll_teacher(@teacher2, enrollment_state: 'active')

      # create moderated assignment
      @moderated_assignment = @course.assignments.create!(
        title: 'Moderated Assignment1',
        grader_count: 2,
        final_grader_id: @teacher.id,
        grading_type: 'points',
        points_possible: 15,
        submission_types: 'online_text_entry',
        moderated_grading: true
      )

      # switch session to non-final-grader
      user_session(@teacher2)
    end

    it 'prevents unmuting the assignment before grades are posted', priority: '2', test_id: 3493531 do
      Speedgrader.visit(@course.id, @moderated_assignment.id)

      expect(Speedgrader.mute_button.attribute('data-muted')).to eq 'true'
      expect(Speedgrader.mute_button.attribute('class')).to include 'disabled'
    end

    it 'allows unmuting the assignment after grades are posted', priority: '2', test_id: 3493531 do
      @moderated_assignment.update!(grades_published_at: Time.zone.now)
      Speedgrader.visit(@course.id, @moderated_assignment.id)

      expect(Speedgrader.mute_button.attribute('class')).not_to include 'disabled'
    end
  end
end

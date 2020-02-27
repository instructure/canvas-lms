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
require_relative '../pages/gradebook_page'
require_relative '../pages/gradebook/settings'
require_relative '../pages/gradebook_cells_page'
require_relative '../pages/srgb_page'
require_relative '../pages/student_grades_page'

describe 'Final Grade Override' do
  include_context 'in-process server selenium tests'

  before(:once) do
    course_with_teacher(course_name: "Grade Override", active_course: true,active_enrollment: true,name: "Teacher Boss1",active_user: true)
    @course.update!(grading_standard_enabled: true)
    @students = create_users_in_course(@course, 5, return_type: :record, name_prefix: "Purple")
    @course.enable_feature!(:final_grades_override)

    # create moderated assignment with teacher4 as final grader
    @assignment = @course.assignments.create!(
      title: 'override assignment',
      submission_types: 'online_text_entry',
      grading_type: 'points',
      points_possible: 10
    )

    @students.each do |student|
      @assignment.grade_student(student, grade: 8.9, grader: @teacher)
    end
  end

  context "Individual Gradebook" do
    before(:once) do
      @student = @students.first
      @enrollment = @course.enrollments.find_by(user: @student)
      @enrollment.scores.find_by(course_score: true).update!(override_score: 97.1)
    end

    before(:each) do
      user_session(@teacher)
      SRGB.visit(@course.id)
      SRGB.allow_final_grade_override_option.click
      SRGB.select_student(@student)
    end

    it 'display override percent in individual gradebook', priority: '1', test_id: 3682130 do
      expect(SRGB.final_grade_override.text).to include "97.1%"
    end

    it 'display override grade in individual gradebook', priority: '1', test_id: 3682130 do
      expect(SRGB.final_grade_override_input).to have_value "A"
    end

    it 'saves overridden grade in SRGB', priority: '1', test_id: 3682131 do
      SRGB.enter_override_grade('D-')
      expect(@enrollment.scores.find_by(course_score: true).override_score).to be 61.0
    end
  end

  it 'displays the override column', priority: '1', test_id: 3682130 do
    user_session(@teacher)
    Gradebook.visit(@course)
    Gradebook.settings_cog_select
    Gradebook::Settings.click_advanced_tab
    Gradebook::Advanced.select_grade_override_checkbox
    Gradebook::Settings.click_update_button
    expect(f(".slick-header-column[title='Override']")).to be_displayed
  end

  context 'with an overridden grade' do
    before(:each) do
      @course.update!(allow_final_grade_override: true)
      @teacher.save

      user_session(@teacher)
      Gradebook.visit(@course)
      Gradebook::Cells.edit_override(@students.first, 90.0)
    end

    it 'saves overridden grade in Gradebook', priority: '1', test_id: 3682131 do
      Gradebook.visit(@course)
      expect(Gradebook::Cells.get_override_grade(@students.first)).to eql "A-"
    end

    it 'displays overridden grade for student grades', priority: '1', test_id: 3682131 do
      user_session(@students.first)
      StudentGradesPage.visit_as_student(@course)
      expect(StudentGradesPage.final_grade.text).to eql "90%"
    end
  end
end

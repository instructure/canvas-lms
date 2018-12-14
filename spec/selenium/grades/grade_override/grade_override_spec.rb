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
require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla/settings/advanced'
require_relative '../pages/gradezilla_cells_page'
require_relative '../pages/srgb_page'
require_relative '../pages/student_grades_page'

describe 'Final Grade Override' do
  include_context 'in-process server selenium tests'

  before(:once) do
    course_with_teacher(course_name: "Grade Override", active_course: true,active_enrollment: true,name: "Teacher Boss1",active_user: true)
    @course.update!(grading_standard_enabled: true)
    @students = create_users_in_course(@course, 5, return_type: :record, name_prefix: "Purple")
    Account.default.enable_feature!(:final_grades_override)
    @course.enable_feature!(:new_gradebook)

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
      enrollment = @course.enrollments.find_by(user: @student)
      enrollment.scores.find_by(course_score: true).update!(override_score: 97.1)
    end

    before(:each) do
      user_session(@teacher)
      SRGB.visit(@course.id)
      SRGB.show_final_grade_override_option.click
      SRGB.select_student(@student)
    end

    it 'display override percent in individual gradebook', priority: '1', test_id: 3682130 do
      expect(SRGB.final_grade_override.text).to include "97.1%"
    end

    it 'display override grade in individual gradebook', priority: '1', test_id: 3682130 do
      expect(SRGB.final_grade_override_grade).to have_value "A"
    end

    it 'saves overridden grade in SRGB', priority: '1', test_id: 3682131 do
      skip('Unskip in GRADE-1890')
      SRGB.visit(@course.id)
      # TODO: displays on SRGB, not sure what this will look like yet
    end
  end

  context "Gradezilla" do
    it 'display override column in new gradebook', priority: '1', test_id: 3682130 do
      user_session(@teacher)
      Gradezilla.visit(@course)
      Gradezilla.settings_cog_select
      Gradezilla::Settings.click_advanced_tab
      Gradezilla::Settings::Advanced.select_grade_override_checkbox
      Gradezilla::Settings.click_update_button
      expect(f(".slick-header-column[title='Override']")).to be_displayed
    end

    context 'with an overridden grade' do
      before(:each) do
        @teacher.preferences.deep_merge!({
          gradebook_settings: { @course.id => { 'show_final_grade_overrides' => 'true' } }
        })
        @teacher.save

        user_session(@teacher)
        Gradezilla.visit(@course)
        Gradezilla::Cells.edit_override(@students.first, 90.0)
      end

      it 'saves overridden grade in Gradezilla', priority: '1', test_id: 3682131 do
        Gradezilla.visit(@course)
        expect(Gradezilla::Cells.get_override_grade(@students.first)).to eql "A-"
      end

      it 'displays overridden grade for student grades', priority: '1', test_id: 3682131 do
        skip('GRADE-1931')
        user_session(@students.first)
        StudentGradesPage.visit_as_student(@course)
        expect(StudentGradesPage.final_grade.text).to eql "90%"
      end
    end
  end
end

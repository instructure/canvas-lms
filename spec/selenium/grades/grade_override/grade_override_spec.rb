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
require_relative '../pages/gradezilla_advanced_options_page'
require_relative '../pages/gradezilla_main_settings'
require_relative '../pages/gradezilla_cells_page'
require_relative '../pages/srgb_page'
require_relative '../pages/student_grades_page'

describe 'Final Grade Override' do
  include_context 'in-process server selenium tests'

  before(:once) do
    skip('Unskip in GRADE-1867')
    course_with_teacher(course_name: "Grade Override", active_course: true,active_enrollment: true,name: "Teacher Boss1",active_user: true)
    @students = create_users_in_course(@course, 5, return_type: :record, name_prefix: "Purple")
    Account.default.enable_feature!(:final_grades_override)

    # create moderated assignment with teacher4 as final grader
    @assignment = @course.assignments.create!(
      title: 'override assignment',
      submission_types: 'online_text_entry',
      grading_type: 'points',
      points_possible: 10
    )

    @students.each do |student|
      @assignment.grade_student(student, grade: 9.2, grader: @teacher)
    end

  end

  before(:each) do
    user_session(@teacher)
    Gradezilla.visit(@course)
    Gradezilla.settings_cog_select
    #select option for override
    MainSettings::Advanced.grade_override_checkbox.click
    MainSettings::Controls.click_update_button
  end

  it 'display override column in new gradebook', priority: '1', test_id: 3682130 do
    skip('Unskip in GRADE-1867')
    # TODO: verify new column on NG
    expect(f(".slick-header-column[title='Override']")).to be_displayed
  end

  it 'display override area in individual gradebook', priority: '1', test_id: 3682130 do
    skip('Unskip in GRADE-81')
    # TODO: verify new area in individual gradebook
  end

  context 'with overriden grade' do
    before(:each) do
      skip('Unskip in GRADE-1688')
      # TODO: override grade
      Gradezilla::Cells.edit_override(@students.first, 5)
    end

    it 'saves overriden grade in Gradezilla', priority: '1', test_id: 3682131 do
      skip('Unskip in GRADE-1688')
      Gradezilla.visit(@course)
      # TODO: displays on NG
      expect(Gradezilla::Cells.get_override_grade(@students.first)).to equal 5
    end

    it 'saves overriden grade in SRGB', priority: '1', test_id: 3682131 do
      skip('Unskip in GRADE-81')
      SRGB.visit(@course.id)
      # TODO: displays on SRGB, not sure what this will look like yet
    end

    it 'displays overriden grade for student grades', priority: '1', test_id: 3682131 do
      skip('Unskip in GRADE-1688')
      # TODO: displays on Student grades page
      user_session(@students.first)
      StudentGradesPage.visit_as_student(@course)

      expect(StudentGradesPage.fetch_assignment_score(@assignment)).to equal 5
    end
  end
end

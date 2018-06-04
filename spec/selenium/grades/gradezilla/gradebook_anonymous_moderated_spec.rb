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

require_relative '../pages/gradezilla_cells_page'
require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla_grade_detail_tray_page'

describe 'Anonymous Moderated Marking' do
  include_context 'in-process server selenium tests'

  before(:each) do
    Account.default.enable_feature!(:anonymous_moderated_marking)

    # create a course with a teacher
    course_with_teacher(course_name: 'Course1', active_all: true)
  end

  context 'with Anonymous Marking Flag ON' do
    before(:each) do
      Account.default.enable_feature!(:anonymous_marking)
      @student1 = student_in_course.user

      # create a new anonymous assignment
      @anonymous_assignment = @course.assignments.create!(
        title: 'Anonymous Assignment',
        submission_types: 'online_text_entry',
        anonymous_grading: true,
        points_possible: 10
      )

      # create a regular non-anonymous assignment
      @non_anonymous_assignment = @course.assignments.create!(
        title: 'Non Anonymous Assignment',
        submission_types: 'online_text_entry',
        points_possible: 10
      )
    end

    it 'new anonymous assignment is muted by default', priority: '1', test_id: 3500571 do
      expect(@anonymous_assignment.muted?).to be true
    end

    it 'score cell disabled in tray in New Gradebook' do # test_id: 3500571
      user_session(@teacher)
      Gradezilla.visit(@course)
      Gradezilla::Cells.open_tray(@student1, @anonymous_assignment)

      expect(Gradezilla::GradeDetailTray.grade_input).to have_attribute('aria-disabled', 'true')
    end

    it 'existing assignment is muted when anonymous-grading is enabled', priority: '1', test_id: 3500572 do
      expect(@non_anonymous_assignment.muted?).to be false
      # make the assignment anonymous
      @non_anonymous_assignment.update!(anonymous_grading: true)

      expect(@anonymous_assignment.muted?).to be true
    end
  end
end

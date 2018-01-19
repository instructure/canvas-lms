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

require_relative '../../helpers/gradezilla_common'
require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla_cells_page'

describe "Gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon

  describe 'letter grade assignment grading' do
    before :once do
      init_course_with_students 1
      @assignment = @course.assignments.create!(grading_type: 'letter_grade', points_possible: 10)
      @assignment.grade_student(@students[0], grade: 'B', grader: @teacher)
    end

    before :each do
      user_session(@teacher)
      Gradezilla.visit(@course)
    end

    it 'is maintained in editable mode', priority: "1", test_id: 3438379 do
      Gradezilla::Cells.select_scheme_grade(@students[0], @assignment, 'C')
      expect(Gradezilla::Cells.get_grade(@students[0], @assignment)).to eq('C')
    end

    it 'is maintained on page refresh post grade update', priority: "1", test_id: 3438380 do
      Gradezilla::Cells.select_scheme_grade(@students[0], @assignment, 'A-')
      refresh_page
      expect(Gradezilla::Cells.get_grade(@students[0], @assignment)).to eq('A-')
    end
  end
end

# frozen_string_literal: true

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

require_relative '../../helpers/gradebook_common'
require_relative '../pages/gradebook_page'
require_relative '../pages/gradebook_cells_page'
require_relative '../setup/assignment_grade_type_setup'

describe "Gradebook" do
  include_context "in-process server selenium tests"
  include AssignmentGradeTypeSetup

  describe 'complete/incomplete assignment grading' do
    before :once do
      assignments_with_grades_setup('pass_fail', 'pass')
    end

    before :each do
      user_session(@teacher)
      Gradebook.visit(@course)
    end

    it 'is maintained in editable mode', priority: '1', test_id: 3426618 do
      Gradebook::Cells.grading_cell(@students[0], @assignment).click
      title = f("#{Gradebook::Cells.grading_cell_selector(@students[0], @assignment)} title")
      expect(title.attribute(:innerHTML)).to eq 'Complete'
    end

    it 'is maintained on page refresh post grade update', priority: '1', test_id: 3435317 do
      Gradebook::Cells.select_complete_incomplete_grade(@students[0], @assignment, 'Incomplete')
      refresh_page
      expect(Gradebook::Cells.get_grade(@students[0], @assignment)).to eq 'Incomplete'
    end
  end
end

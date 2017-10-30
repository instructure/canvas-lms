#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../pages/gradebook_history_page'
require_relative '../setup/gb_history_search_setup'

describe "Gradebook History Page" do
  include_context "in-process server selenium tests"
  include GradebookHistorySetup
  include CustomScreenActions

  before(:once) do
    gb_history_setup(2)
  end

  before(:each) do
    user_session(@teacher)
    GradeBookHistory.visit(@course)
    wait_for_ajaximations
  end

  context "shows the results table for a valid search" do

    it "with student name input and typeahead selection", test_id: %w(3308073 3308054), priority: "1" do
        student_name=@course.students.first.name
        GradeBookHistory.search_with_student_name(
          student_name[0...3], student_name
        )
        expect(GradeBookHistory.check_table_for_student_name(student_name)).to be true
    end

    it "with grader name input and typeahead selection", test_id: %w(3308073 3308054), priority: "1" do
      GradeBookHistory.search_with_grader_name(
        @teacher.email
      )
      expect(GradeBookHistory.check_table_for_grader_name(@teacher.email)).to be true
    end

    it "with all assignment name and typeahead selection", test_id: %w(3308073 3308054), priority: "1" do
      GradeBookHistory.search_with_assignment_name(
        @assignment_past_due_day.title
      )
      expect(GradeBookHistory.check_table_for_assignment_name(@assignment_past_due_day.title)).to be true
    end

    it "and the current grade column has the same grade as related grade history rows", test_id: 3308871, priority: "1" do
        expect(GradeBookHistory.check_current_col_for_history('assignment two')).to be true
    end
  end
end

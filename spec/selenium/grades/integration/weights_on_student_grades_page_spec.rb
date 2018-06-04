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

require_relative '../pages/student_grades_page'
require_relative './weighting_setup'
require_relative './a_gradebook_shared_example'

describe 'gradezilla' do
  include_context "in-process server selenium tests"
  include WeightingSetup

  let(:total_grade) do
    grading_period_titles = ["All Grading Periods", @gp1.title, @gp2.title]
    user_session(@teacher)
    StudentGradesPage.visit_as_teacher(@course, @student)

    if @grading_period_index
      title = grading_period_titles[@grading_period_index]
      StudentGradesPage.select_period_by_name(title)
      StudentGradesPage.click_apply_button unless title == "All Grading Periods"
    end
    StudentGradesPage.final_grade.text
  end

  let(:individual_view) { false }

  before(:once) do
    weighted_grading_setup
  end

  it_behaves_like 'a gradebook'
end

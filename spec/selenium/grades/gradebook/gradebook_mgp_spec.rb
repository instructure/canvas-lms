#
# Copyright (C) 2015-2016 Instructure, Inc.
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
#

require_relative '../../common'
require_relative '../page_objects/gradebook_page'
require_relative '../setup/gradebook_setup'

describe "gradebook - multiple grading periods" do
  include_context "in-process server selenium tests"
  include GradebookSetup

  context 'with close and end dates' do
    let(:gb_mgp_page) { Gradebook::MultipleGradingPeriods.new }

    before(:once) do
      term_name = "First Term"
      create_multiple_grading_periods(term_name)
      add_teacher_and_student
      associate_course_to_term(term_name)
      user_session(@teacher)
    end

    it 'assignment in ended gp should be gradable', test_id: 2947119, priority: "1" do
      @course.assignments.create!(due_at: 13.days.ago, title: "assign in ended")
      gb_mgp_page.visit_gradebook(@course)

      gb_mgp_page.select_grading_period(0)
      gb_mgp_page.enter_grade("10", 0, 0)
      expect(gb_mgp_page.cell_graded?("10", 0, 0)).to be true

      gb_mgp_page.select_grading_period(@gp_ended.id)
      gb_mgp_page.enter_grade("8", 0, 0)
      expect(gb_mgp_page.cell_graded?("8", 0, 0)).to be true
    end
  end
end
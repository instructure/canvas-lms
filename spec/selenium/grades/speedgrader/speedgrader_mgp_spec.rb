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
require_relative '../page_objects/speedgrader_page'
require_relative '../setup/gradebook_setup'

describe "speedgrader with grading periods" do
  include_context "in-process server selenium tests"
  include GradebookSetup

  context 'with close and end dates' do
    before do
      term_name = "First Term"
      create_grading_periods(term_name)
      add_teacher_and_student
      associate_course_to_term(term_name)
    end

    before do
      user_session(@teacher)
    end

    it 'assignment in ended gp should be gradable', test_id: 2947134, priority: "1" do
      assignment = @course.assignments.create!(due_at: 13.days.ago, title: "assign in ended")
      Speedgrader.visit(@course.id, assignment.id)
      Speedgrader.enter_grade(8)

      expect(Speedgrader.current_grade).to eq "8"
      expect(Submission.where(assignment_id: assignment.id, user_id: @student.id).first.grade).to eq "8"
    end

    it 'assignment in closed gp should not be gradable', test_id: 2947133, priority: "1" do
      assignment = @course.assignments.create!(due_at: 18.days.ago, title: "assign in closed")
      Speedgrader.visit(@course.id, assignment.id)
      Speedgrader.enter_grade(8)

      expect(Speedgrader.current_grade).to eq ""
      expect(Submission.where(assignment_id: assignment.id, user_id: @student.id).first).to eq nil
      expect(Speedgrader.top_bar).to contain_css(Speedgrader.closed_gp_notice_selector)
    end
  end
end

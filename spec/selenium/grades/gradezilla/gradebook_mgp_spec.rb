#
# Copyright (C) 2016 - present Instructure, Inc.
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
require_relative '../pages/gradezilla_page'
require_relative '../pages/gradezilla_cells_page'
require_relative '../setup/gradebook_setup'

describe "Gradezilla with grading periods" do
  include_context "in-process server selenium tests"
  include GradebookSetup

  context 'with close and end dates' do
    now = Time.zone.now

    before(:once) do
      term_name = "First Term"
      create_grading_periods(term_name, now)
      add_teacher_and_student
      associate_course_to_term(term_name)
      show_grading_periods_filter(@teacher)
    end

    context 'as a teacher' do
      before(:each) do
        user_session(@teacher)
      end

      it 'assignment in ended grading period should be gradable', test_id: 2947119, priority: "1" do
        assign = @course.assignments.create!(due_at: 13.days.ago(now), title: "assign in ended")
        Gradezilla.visit(@course)

        Gradezilla.select_grading_period("All Grading Periods")
        Gradezilla::Cells.edit_grade(@student, assign, "10")
        expect { Gradezilla::Cells.get_grade(@student, assign) }.to become "10"


        Gradezilla.select_grading_period(@gp_ended.title)
        Gradezilla::Cells.edit_grade(@student, assign, "8")
        expect { Gradezilla::Cells.get_grade(@student, assign) }.to become "8"
      end
    end

    context 'as an admin' do
      before(:each) do
        account_admin_user(account: Account.site_admin)
        user_session(@admin)
        show_grading_periods_filter(@admin)
      end

      it 'assignment in closed grading period should be gradable', test_id: 2947126, priority: "1" do
        assignment = @course.assignments.create!(due_at: 18.days.ago(now), title: "assign in closed")
        Gradezilla.visit(@course)

        Gradezilla.select_grading_period(@gp_closed.title)
        Gradezilla::Cells.edit_grade(@student, assignment, "10")
        expect { Gradezilla::Cells.get_grade(@student, assignment) }.to become "10"
        expect(Submission.where(assignment_id: assignment.id, user_id: @student.id).first.grade).to eq "10"
      end
    end

    it 'assignment in closed gp should not be gradable', test_id: 2947118, priority: "1" do
      user_session(@teacher)

      assign = @course.assignments.create!(due_at: 18.days.ago, title: "assign in closed")
      Gradezilla.visit(@course)

      Gradezilla.select_grading_period("All Grading Periods")
      expect(Gradezilla::Cells.grading_cell(@student, assign)).to contain_css(Gradezilla::Cells.ungradable_selector)

      Gradezilla.select_grading_period(@gp_closed.title)
      expect(Gradezilla::Cells.grading_cell(@student, assign)).to contain_css(Gradezilla::Cells.ungradable_selector)
    end
  end
end

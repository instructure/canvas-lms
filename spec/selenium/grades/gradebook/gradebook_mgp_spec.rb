# frozen_string_literal: true

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

require_relative "../../common"
require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook_cells_page"
require_relative "../setup/gradebook_setup"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Gradebook with grading periods" do |ff_enabled|
  include_context "in-process server selenium tests"
  include GradebookSetup

  before :once do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
  end

  context "with close and end dates" do
    now = Time.zone.now

    before(:once) do
      term_name = "First Term"
      create_grading_periods(term_name, now)
      add_teacher_and_student
      associate_course_to_term(term_name)
      show_grading_periods_filter(@teacher)
    end

    context "as a teacher" do
      before do
        user_session(@teacher)
      end

      it "assignment in ended grading period should be gradable", priority: "1" do
        assign = @course.assignments.create!(due_at: 13.days.ago(now), title: "assign in ended")
        Gradebook.visit(@course)

        Gradebook.select_grading_period("All Grading Periods")
        Gradebook::Cells.edit_grade(@student, assign, "10")
        expect { Gradebook::Cells.get_grade(@student, assign) }.to become "10"

        Gradebook.select_grading_period(@gp_ended.title)
        Gradebook::Cells.edit_grade(@student, assign, "8")
        expect { Gradebook::Cells.get_grade(@student, assign) }.to become "8"
      end
    end

    context "as an admin" do
      before do
        account_admin_user(account: Account.site_admin)
        user_session(@admin)
        show_grading_periods_filter(@admin)
      end

      it "assignment in closed grading period should be gradable", priority: "1" do
        assignment = @course.assignments.create!(due_at: 18.days.ago(now), title: "assign in closed")
        Gradebook.visit(@course)

        Gradebook.select_grading_period(@gp_closed.title)
        Gradebook::Cells.edit_grade(@student, assignment, "10")
        expect { Gradebook::Cells.get_grade(@student, assignment) }.to become "10"
        expect(Submission.where(assignment_id: assignment.id, user_id: @student.id).first.grade).to eq "10"
      end
    end

    it "assignment in closed gp should not be gradable", priority: "1" do
      user_session(@teacher)

      assign = @course.assignments.create!(due_at: 18.days.ago, title: "assign in closed")
      Gradebook.visit(@course)

      Gradebook.select_grading_period("All Grading Periods")
      expect(Gradebook::Cells.grading_cell(@student, assign)).to contain_css(Gradebook::Cells.ungradable_selector)

      Gradebook.select_grading_period(@gp_closed.title)
      expect(Gradebook::Cells.grading_cell(@student, assign)).to contain_css(Gradebook::Cells.ungradable_selector)
    end
  end
end

describe "Gradebook with grading periods" do
  it_behaves_like "Gradebook with grading periods", true
  it_behaves_like "Gradebook with grading periods", false
end

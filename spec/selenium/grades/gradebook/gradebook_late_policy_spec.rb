# frozen_string_literal: true

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

require_relative "../pages/gradebook_page"
require_relative "../pages/gradebook_cells_page"
require_relative "../pages/gradebook/settings"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "Late Policies:" do |ff_enabled|
  include_context "in-process server selenium tests"

  before :once do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
  end

  context "when applied" do
    before(:once) do
      now = Time.zone.now

      # create course with teacher and student
      course_factory(active_all: true)
      student_in_course

      # create late/missing policies on backend
      @course.create_late_policy(
        missing_submission_deduction_enabled: true,
        missing_submission_deduction: 25.0,
        late_submission_deduction_enabled: true,
        late_submission_deduction: 10.0,
        late_submission_interval: "day",
        late_submission_minimum_percent_enabled: true,
        late_submission_minimum_percent: 50.0
      )

      # create 3 assignments due in the past
      @a1 = @course.assignments.create!(
        title: "assignment one",
        grading_type: "points",
        points_possible: 100,
        due_at: 1.day.ago(now),
        submission_types: "online_text_entry"
      )

      @a2 = @course.assignments.create!(
        title: "assignment two",
        grading_type: "points",
        points_possible: 100,
        due_at: 1.day.ago(now),
        submission_types: "online_text_entry"
      )

      @a3 = @course.assignments.create!(
        title: "assignment three",
        grading_type: "points",
        points_possible: 10,
        due_at: 1.week.ago(now),
        submission_types: "online_text_entry"
      )

      # paper assignment
      @a4 = @course.assignments.create!(
        title: "assignment four",
        grading_type: "pass_fail",
        points_possible: 10,
        due_at: 1.day.ago(now),
        submission_types: "on_paper"
      )

      # pass/fail assignment
      @a5 = @course.assignments.create!(
        title: "assignment five",
        grading_type: "pass_fail",
        points_possible: 10,
        due_at: 1.day.ago(now),
        submission_types: "online_text_entry"
      )

      # no-submission assignment
      @a6 = @course.assignments.create!(
        title: "assignment six",
        grading_type: "points",
        points_possible: 0,
        due_at: 1.day.ago(now),
        submission_types: "none"
      )

      # as a student submit 2 assignments late
      Timecop.freeze(2.hours.ago(now)) do
        @a1.submit_homework(@student, body: "submitting my homework")
        @a3.submit_homework(@student, body: "submitting my homework")
      end

      # as a teacher grade the late assignments
      @a1.grade_student(@student, grade: 90, grader: @teacher)
      @a3.grade_student(@student, grade: 9, grader: @teacher)
    end

    before do
      user_session(@teacher)
      Gradebook.visit(@course)
    end

    it "late policy adjusts grades correctly", priority: "1" do
      expect(Gradebook::Cells.get_grade(@student, @a1)).to eq "80"
    end

    it "missing policy adjusts grades correctly", priority: "1" do
      expect(Gradebook::Cells.get_grade(@student, @a2)).to eq "75"
    end

    it "late policy with floor adjust the grades correctly", priority: "1" do
      expect(Gradebook::Cells.get_grade(@student, @a3)).to eq "5"
    end

    it "missing/late deductions dont affect paper assignments", priority: "1" do
      expect(Gradebook::Cells.get_grade(@student, @a4)).to eq "–"
    end

    it "missing policy adjusts pass/fail assignment", priority: "1" do
      expect(Gradebook::Cells.get_grade(@student, @a5)).to eq "Incomplete"
    end

    it "late & missing policy wont affect no-submission assignment", priority: "2" do
      expect(Gradebook::Cells.get_grade(@student, @a6)).to eq "–"
    end

    it "late penalty re-applied if submission graded same as its effective grade", priority: "2" do
      # re-grade student's @a1 assignment that is late and has previous deductions
      Gradebook::Cells.edit_grade(@student, @a1, "80")
      expect { Gradebook::Cells.get_grade(@student, @a1) }.to become "70"
    end

    it "updates score when late policy changes", priority: "1" do
      @course.late_policy.update(late_submission_deduction: 20.0)
      refresh_page
      expect(Gradebook::Cells.get_grade(@student, @a1)).to eq "70"
    end

    it "once applied, missing policy change does not re-trigger score change", priority: "2" do
      @course.late_policy.update(missing_submission_deduction: 50.0, missing_submission_deduction_enabled: false)
      # disable and then re-enable updated missing policy
      @course.late_policy.update(missing_submission_deduction_enabled: true)
      refresh_page
      expect(Gradebook::Cells.get_grade(@student, @a2)).to eq "75"
    end
  end

  context "when created" do
    before(:once) do
      course_factory(active_all: true)
      student_in_course
    end

    before do
      user_session(@teacher)
      Gradebook.visit(@course)
      Gradebook.settings_cog_select
    end

    it "saves late policy", priority: "1" do
      percentage = 10
      increment = "Day"
      Gradebook::LatePolicies.create_late_policy(percentage, increment)
      Gradebook::Settings.click_update_button

      expect(@course.late_policy.late_submission_deduction_enabled).to be true
      expect(@course.late_policy.late_submission_deduction.to_i).to be percentage
      expect(@course.late_policy.late_submission_interval).to eq increment.downcase
    end

    it "saves missing policy", priority: "1" do
      percentage = 50
      Gradebook::LatePolicies.create_missing_policy(percentage)
      Gradebook::Settings.click_update_button

      expect(@course.late_policy.missing_submission_deduction_enabled).to be true
      expect(@course.late_policy.missing_submission_deduction.to_i).to be percentage
    end

    it "saves late policy with floor", priority: "1" do
      percentage = 10
      increment = "Day"
      lowest_percentage = 50
      Gradebook::LatePolicies.create_late_policy(percentage, increment, lowest_percentage)
      Gradebook::Settings.click_update_button

      expect(@course.late_policy.late_submission_minimum_percent_enabled).to be true
      expect(@course.late_policy.late_submission_minimum_percent.to_i).to be lowest_percentage
    end
  end
end

describe "Late Policies:" do
  it_behaves_like "Late Policies:", true
  it_behaves_like "Late Policies:", false
end

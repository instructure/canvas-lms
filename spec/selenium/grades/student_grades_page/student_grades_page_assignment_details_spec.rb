# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../helpers/gradebook_common"
require_relative "../setup/gradebook_setup"
require_relative "../pages/student_grades_page"

describe "Student Gradebook - Assignment Details" do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup

  context "grade distribution totals" do
    let(:assignments) do
      assignments = []
      (1..3).each do |i|
        assignment = @course.assignments.create!(
          title: "Assignment #{i}",
          points_possible: 20
        )
        assignments.push assignment
      end
      assignments
    end

    grades = [
      5,
      10,
      15,
      19,
      15,
      10,
      4,
      6,
      17
    ]

    before do
      init_course_with_students 3
      user_session(@teacher)
      means = []
      [0, 3, 6].each do |i|
        # the format below ensures that 18.0 is displayed as 18.
        mean = format("%g", format("%.2f", grades[i, 3].sum.to_f / 3)).to_s
        means.push mean
      end

      @expectations = [
        { high: "15", low: "5", mean: means[0] },
        { high: "19", low: "10", mean: means[1] },
        { high: "17", low: "4", mean: means[2] }
      ]

      grades.each_with_index do |grade, index|
        assignments[index / 3].grade_student @students[index % 3], grade:, grader: @teacher
      end
    end

    context "when user is not quantitative data restricted" do
      it "shows assignment grade distribution" do
        get "/courses/#{@course.id}/grades/#{@students[0].id}"
        f("#show_all_details_button").click
        details = ff('[id^="score_details"] td')

        @expectations.each_with_index do |expectation, index|
          i = index * 4 # each detail row has 4 items, we only want the first 3
          expect(details[i]).to include_text "Mean: #{expectation[:mean]}"
          expect(details[i + 1]).to include_text "High: #{expectation[:high]}"
          expect(details[i + 2]).to include_text "Low: #{expectation[:low]}"
        end

        f("#show_all_details_button").click
        details = ff('[id^="grade_info"]')
        details.each do |detail|
          expect(detail.css_value("display")).to eq "none"
        end
      end
    end

    context "when user is quantitative data restricted" do
      before :once do
        # truthy feature flag
        Account.default.enable_feature! :restrict_quantitative_data

        # truthy setting
        Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
        Account.default.save!
      end

      it "does not show grade distribution" do
        get "/courses/#{@course.id}/grades/#{@students[0].id}"
        f("#show_all_details_button").click
        wait_for_ajaximations
        # show all details will do nothing in this case, since there are no grade distribution(due to quantitative data restriction)
        # nor submission comments to show
        # there is no grade distribution implementation for quantitative data restricted users
        # so expecting the table row's text to be exactly like below makes sure no grade distribution is showing
        expect(ff("#grade-summary-react tr")[1].text).to eq "Assignment 1\nAssignments\nGraded\nF\nYour grade has been updated"
      end
    end
  end

  context "submission comments" do
    before :once do
      init_course_with_students 1
      @asn = @course.assignments.create!(title: "my assignment", submission_types: ["online_text_entry"], points_possible: 10)
      @sub = @asn.submit_homework(@students[0], body: "my submission", submission_type: "online_text_entry")
    end

    context "when user is not quantitative data restricted" do
      it "displays submission comments" do
        @asn.grade_student(@students[0], grade: "10", grader: @teacher)
        @sub.submission_comments.create!(comment: "good job")
        user_session @students[0]
        get "/courses/#{@course.id}/grades"
        f("a[aria-label='Read comments']").click
        expect(StudentGradesPage.submission_comments.first).to include_text "good job"
      end

      it "does not show submission comments if assignment is muted" do
        @asn.ensure_post_policy(post_manually: true)
        @sub.submission_comments.create!(comment: "good job")
        user_session @students[0]
        get "/courses/#{@course.id}/grades"
        muted_row = f("tr#submission_#{@asn.id}")
        expect(muted_row).to contain_jqcss("i[title='Instructor has not posted this grade']")
        expect(f("a[aria-label='Read comments']").attribute("style")).to eq "visibility: hidden;"
      end
    end

    context "when user is quantitative data restricted" do
      before :once do
        # truthy feature flag
        Account.default.enable_feature! :restrict_quantitative_data

        # truthy setting
        Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
        Account.default.save!
        @course.restrict_quantitative_data = true
        @course.save!
      end

      it "shows submission comments", :ignore_js_errors do
        @asn.grade_student(@students[0], grade: "10", grader: @teacher)
        @sub.submission_comments.create!(comment: "good job")
        user_session @students[0]
        get "/courses/#{@course.id}/grades"
        fj("tr button:contains('Submission Comments')").click
        expect(f("[aria-label='Submission Comments Tray']").text).to include "good job"
      end

      it "has no submission comments button when muted" do
        @asn.ensure_post_policy(post_manually: true)
        @sub.submission_comments.create!(comment: "good job")
        user_session @students[0]
        get "/courses/#{@course.id}/grades"
        expect(f("body")).not_to contain_jqcss("tr button:contains('Submission Comments')")
        expect(f("svg[name='IconMuted']")).to be_present
      end
    end
  end
end

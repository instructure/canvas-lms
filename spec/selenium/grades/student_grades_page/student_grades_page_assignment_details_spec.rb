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

    it "shows assignment grade distribution", priority: "1" do
      init_course_with_students 3
      user_session(@teacher)

      means = []
      [0, 3, 6].each do |i|
        # the format below ensures that 18.0 is displayed as 18.
        mean = format("%g", format("%.2f", grades[i, 3].sum.to_f / 3)).to_s
        means.push mean
      end

      expectations = [
        { high: "15", low: "5", mean: means[0] },
        { high: "19", low: "10", mean: means[1] },
        { high: "17", low: "4", mean: means[2] }
      ]

      grades.each_with_index do |grade, index|
        assignments[index / 3].grade_student @students[index % 3], grade:, grader: @teacher
      end

      get "/courses/#{@course.id}/grades/#{@students[0].id}"
      f("#show_all_details_button").click
      details = ff('[id^="score_details"] td')

      expectations.each_with_index do |expectation, index|
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

  context "submission comments" do
    before :once do
      init_course_with_students 1
      @asn = @course.assignments.create!(title: "my assignment", submission_types: ["online_text_entry"], points_possible: 10)
      @sub = @asn.submit_homework(@students[0], body: "my submission", submission_type: "online_text_entry")
    end

    it "displays submission comments" do
      @asn.grade_student(@students[0], grade: "10", grader: @teacher)
      @sub.submission_comments.create!(comment: "good job")
      user_session @students[0]
      get "/courses/#{@course.id}/grades"
      f("a[aria-label='Read comments']").click
      expect(f(".score_details_table").text).to include "good job"
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
end

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

require_relative "../../common"

describe "speed grader - grade display" do
  include_context "in-process server selenium tests"

  before do
    # truthy feature flag
    Account.default.enable_feature! :restrict_quantitative_data

    # truthy setting
    Account.default.settings[:restrict_quantitative_data] = { value: true }
    Account.default.save!

    course_with_teacher_logged_in

    @course.settings = @course.settings.merge(restrict_quantitative_data: true)
    @course.save!

    @student = User.create!(name: "student")
    @student.register
    @student.pseudonyms.create!(unique_id: "student@example.com", password: "qwertyuiop", password_confirmation: "qwertyuiop")
    @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
  end

  context "course is quantitative data restricted" do
    it "coerces score to letter grade for point assignment" do
      @points_assignment = @course.assignments.create(name: "points assignment", grading_type: "points", points_possible: 10)
      @submission = @points_assignment.submit_homework(@student, body: "student submission text")

      # open speed grader \ submission for student
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@points_assignment.id}&student_id=#{@student.id}"

      grade_input = f("#grading-box-extended")
      grade_label = f("#grading-box-points-possible")

      # Accepts number input converts to letter_grade
      set_value(grade_input, "7")
      f("#grade_container").click
      expect(grade_input.attribute("value")).to eq("C-")
      expect(grade_label.text).to eq("Grade (7 / 10)")

      # Accepts letter_grade and displays correct score
      set_value(grade_input, "")
      set_value(grade_input, "B")
      f("#grade_container").click
      expect(grade_label.text).to eq("Grade (8.6 / 10)")
      expect(grade_input.attribute("value")).to eq("B")
    end

    it "coerces score to letter grade for percent assignment" do
      @percent_assignment = @course.assignments.create(name: "percent", grading_type: "percent", points_possible: 10)
      @percent_assignment.submit_homework(@student, body: "student submission text")

      # open speed grader \ submission for student
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@percent_assignment.id}&student_id=#{@student.id}"

      grade_input = f("#grading-box-extended")
      grade_label = f("#grading-box-points-possible")

      # Accepts number input converts to letter_grade
      set_value(grade_input, "70")
      f("#grade_container").click
      expect(grade_input.attribute("value")).to eq("C-")
      expect(grade_label.text).to eq("Grade (7 / 10)")

      # Accepts letter_grade and displays correct score
      set_value(grade_input, "")
      set_value(grade_input, "B")
      f("#grade_container").click
      expect(grade_label.text).to eq("Grade (8.6 / 10)")
      expect(grade_input.attribute("value")).to eq("B")

      # shows percent after course.restrict_quantitative_data off
      @course.settings = @course.settings.merge(restrict_quantitative_data: false)
      @course.save!
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@percent_assignment.id}&student_id=#{@student.id}"

      grade_input = f("#grading-box-extended")
      expect(grade_input.attribute("value")).to eq("86%")
    end

    context "zero points possible" do
      it "displays the correct value" do
        # positive/0 is A
        # 0/0 is "complete" or letter/0 is "complete"
        # negative/0 is not coerced into letter grade

        @points_assignment = @course.assignments.create(name: "points assignment", grading_type: "points", points_possible: 0)
        @submission = @points_assignment.submit_homework(@student, body: "student submission text")

        # open speed grader \ submission for student
        get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@points_assignment.id}&student_id=#{@student.id}"

        grade_input = f("#grading-box-extended")
        grade_label = f("#grading-box-points-possible")

        # positive/0 is A
        set_value(grade_input, "7")
        f("#grade_container").click
        expect(grade_input.attribute("value")).to eq("A")
        expect(grade_label.text).to eq("Grade (7 / 0)")

        # 0/0 is "complete"
        set_value(grade_input, "")
        set_value(grade_input, "0")
        f("#grade_container").click
        expect(grade_label.text).to eq("Grade (0 / 0)")
        expect(grade_input.attribute("value")).to eq("complete")

        # letter/0 is "complete"
        set_value(grade_input, "")
        set_value(grade_input, "B")
        f("#grade_container").click
        expect(grade_label.text).to eq("Grade (0 / 0)")
        expect(grade_input.attribute("value")).to eq("complete")

        # negative/0 is not coerced into letter grade
        set_value(grade_input, "")
        set_value(grade_input, "-7")
        f("#grade_container").click
        expect(grade_label.text).to eq("Grade (-7 / 0)")
        expect(grade_input.attribute("value")).to eq("-7")
      end
    end
  end
end

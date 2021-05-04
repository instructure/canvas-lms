# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../pages/k5_dashboard_page'
require_relative '../../helpers/k5_common'

describe "student k5 course grades tab" do
  include_context "in-process server selenium tests"
  include K5PageObject
  include K5Common

  before :once do
    student_setup
  end

  before :each do
    user_session @student
  end

  context 'grades tab' do
    it 'shows panda image when no grades posted' do
      get "/courses/#{@subject_course.id}#grades"

      expect(empty_grades_image).to be_displayed
    end
  end

  context 'course grades' do
    before :once do
      @assignment1 = create_assignment(@subject_course, "assignment 1", "assignment1 not submitted", 100)
      @assignment2 = create_dated_assignment(@subject_course, "assignment 2 missing", 1.day.ago(Time.zone.now), 15)
      @assignment3 = create_and_submit_assignment(@subject_course, "assignment 3", "assignment2 submitted", 100)
      @assignment3.grade_student(@student, grader: @teacher, score: "90", points_deducted: 0)
    end

    it 'shows 3 assignments in the list' do
      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list.count).to eq(3)
    end

    it 'shows late assignment as Missing' do
      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[0].text).to include("Missing")
    end

    it 'shows submitted assignment with Submitted info' do
      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[2].text).to include("Submitted")
    end

    it 'shows graded assignment with points awarded' do
      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[2].text).to include("90 pts")
    end

    it 'shows ungraded assignment with no points awarded' do
      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[1].text).to include("\u2014 pts")
    end

    it 'shows the total points of graded assignments' do
      get "/courses/#{@subject_course.id}#grades"

      expect(grades_total.text).to include("90.00%")
    end

    it 'includes the total number of points' do
      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[0].text).to include("Out of 15")
    end
  end

  context 'course grading differences' do
    let(:grading_standard) { create_grading_standard(@subject_course) }
    let(:scheme_subject_grade) { "You got this" }
    let(:student_score) { 75 }

    before :once do
      @assignment = create_and_submit_assignment(@subject_course, "Grading Standards Assignment", 1.day.ago(Time.zone.now), 100)
      @assignment.grade_student(@student, grader: @teacher, score: student_score, points_deducted: 0)
    end

    it 'shows a different grading standard for assignments' do
      @assignment.update!(grading_type: "letter_grade", grading_standard_id: grading_standard.id)

      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[0].text).to include(scheme_subject_grade)
    end

    it 'shows the total score as a percentage with the scheme in parens' do
      @subject_course.update!(grading_standard_enabled: true, grading_standard_id: grading_standard.id)

      get "/courses/#{@subject_course.id}#grades"

      expect(grades_total.text).to include("#{student_score}.00% (#{scheme_subject_grade})")
    end

    it 'shows a letter grade if selected for the assignment' do
      @assignment.update!(grading_type: "letter_grade")

      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[0].text).to include("C")
    end

    it 'shows a percentage grade if selected for the assignment' do
      @assignment.update!(grading_type: "percent")

      get "/courses/#{@subject_course.id}#grades"

      expect(grades_assignments_list[0].text).to include("#{student_score}%")
    end
  end
end

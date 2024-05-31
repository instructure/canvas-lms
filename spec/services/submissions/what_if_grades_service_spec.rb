# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Submissions::WhatIfGradesService do
  describe ".call" do
    before(:once) do
      @course = course_model
      @student = student_in_course(course: @course, active_all: true).user
      @teacher = teacher_in_course(course: @course, active_all: true).user
      @assignment = @course.assignments.create!(title: "Assignment", grading_type: "points", points_possible: 10)
      @submission = @assignment.grade_student(@student, grade: "5", grader: @teacher)[0]
      @current_user = @student
    end

    let(:service) { Submissions::WhatIfGradesService }

    it "should raise an error if the submission is invalid" do
      expect { service.call(@current_user, nil, 5) }.to raise_error("Invalid submission")
    end

    it "calculate the student grade" do
      expect(@submission.student_entered_score).to be_nil

      grade_calculation_result = service.call(@current_user, @submission, 7)

      expect(@submission.student_entered_score).to eq(7)
      expect(grade_calculation_result[0][:current][:grade]).to eq(70.0)
    end

    it "calculate the student grade with negative score" do
      expect(@submission.student_entered_score).to be_nil

      grade_calculation_result = service.call(@current_user, @submission, -7)

      expect(@submission.student_entered_score).to eq(-7)
      expect(grade_calculation_result[0][:current][:grade]).to eq(-70.0)
    end

    it "calculate the student grade with more points than possible" do
      expect(@submission.student_entered_score).to be_nil

      grade_calculation_result = service.call(@current_user, @submission, 17)

      expect(@submission.student_entered_score).to eq(17)
      expect(grade_calculation_result[0][:current][:grade]).to eq(170.0)
    end
  end
end

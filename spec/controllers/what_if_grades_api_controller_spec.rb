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

require_relative "../apis/api_spec_helper"

describe WhatIfGradesApiController do
  describe "what_if_grades" do
    describe "#update" do
      before(:once) do
        @course = course_model
        @student = student_in_course(course: @course, active_all: true).user
        @teacher = teacher_in_course(course: @course, active_all: true).user
        @assignment = @course.assignments.create!(title: "Assignment", grading_type: "points", points_possible: 10)
        @submission = @assignment.grade_student(@student, grade: "5", grader: @teacher)[0]
        @current_user = @student
      end

      before { user_session(@student) }

      it "should return an error if the submission_id is invalid" do
        put :update, params: { id: "invalid", student_entered_score: 5 }, format: :json
        json_response = response.parsed_body
        error_message = json_response["errors"][0]["message"]
        expect(response).to be_not_found
        expect(error_message).to eq("The specified resource does not exist.")
      end

      it "should calculate the student grade" do
        put :update, params: { id: @submission.id, student_entered_score: 10 }, format: :json
        json_response = response.parsed_body
        expect(json_response["submission"]["student_entered_score"]).to eq(10.0)
      end

      it "should calculate the student grade with a negative score" do
        put :update, params: { id: @submission.id, student_entered_score: -10 }, format: :json
        json_response = response.parsed_body
        expect(json_response["submission"]["student_entered_score"]).to eq(-10.0)
      end

      it "should calculate the student grade with more points than possible" do
        put :update, params: { id: @submission.id, student_entered_score: 20 }, format: :json
        json_response = response.parsed_body
        expect(json_response["submission"]["student_entered_score"]).to eq(20.0)
      end

      it "should calculate the student grade with null entered score" do
        put :update, params: { id: @submission.id, student_entered_score: "null" }, format: :json
        json_response = response.parsed_body
        expect(json_response["submission"]["student_entered_score"]).to be_nil
      end

      it "should not allow to modify other students what if scores" do
        other_student = student_in_course(course: @course, active_all: true).user
        submission = @assignment.grade_student(other_student, grade: "5", grader: @teacher)[0]
        put :update, params: { id: submission.id, student_entered_score: 10 }, format: :json
        expect(response).to be_not_found
      end

      it "should return an error if the student_entered_grade is not sent" do
        put :update, params: { id: @submission.id }, format: :json
        json_response = response.parsed_body
        error_message = json_response["error"]
        expect(response).to be_bad_request
        expect(error_message).to eq("student_entered_score is required to be either a number or null.")
      end

      it "should return an error if the student_entered_grade is not a number" do
        put :update, params: { id: @submission.id, student_entered_grade: "abcd" }, format: :json
        json_response = response.parsed_body
        error_message = json_response["error"]
        expect(response).to be_bad_request
        expect(error_message).to eq("student_entered_score is required to be either a number or null.")
      end
    end

    describe "#reset_for_student_course" do
      before(:once) do
        @course = course_model
        @course.update_column(:workflow_state, "available")
        @student = student_in_course(course: @course, active_all: true).user
        @teacher = teacher_in_course(course: @course, active_all: true).user
        @assignment = @course.assignments.create!(title: "Assignment", grading_type: "points", points_possible: 10)
        @current_user = @student
      end

      before { user_session(@student) }

      it "should reset the what if score for the student" do
        submission = @assignment.grade_student(@student, grade: "5", grader: @teacher)[0]
        submission.update_column(:student_entered_score, 7)
        put :reset_for_student_course, params: { course_id: @assignment.course.id }, format: :json
        expect(submission.reload.student_entered_score).to be_nil
      end
    end
  end
end

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

# @API What If Grades
#
# @model Grade
#     {
#       "id": "Grade",
#       "properties": {
#         "grade": {
#           "description": "The grade for the course",
#           "example": 120.0,
#           "type": "number"
#         },
#         "total": {
#           "description": "The total points earned in the course",
#           "example": 24.0,
#           "type": "number"
#         },
#         "possible": {
#           "description": "The total points possible for the course",
#           "example": 20.0,
#           "type": "number"
#         },
#         "dropped": {
#           "description": "The dropped grades for the course",
#           "example": [],
#           "type": "array"
#         }
#       }
#     }
#
# @model AssignmentGroupGrade
#     {
#       "id": "AssignmentGroupGrade",
#       "properties": {
#         "id": {
#           "description": "The ID of the Assignment Group",
#           "example": 123,
#           "type": "integer"
#         },
#         "global_id": {
#           "description": "The global ID of the Assignment Group",
#           "example": 10000000000001,
#           "type": "integer"
#         },
#         "score": {
#           "description": "The score for the Assignment Group",
#           "example": 20.0,
#           "type": "number"
#         },
#         "possible": {
#           "description": "The total points possible for the Assignment Group",
#           "example": 10.0,
#           "type": "number"
#         },
#         "weight": {
#           "description": "The weight for the Assignment Group",
#           "example": 0.0,
#           "type": "number"
#         },
#         "grade": {
#           "description": "The grade for the Assignment Group",
#           "example": 200.0,
#           "type": "number"
#         },
#         "dropped": {
#           "description": "The dropped grades for the Assignment Group",
#           "example": [],
#           "type": "array"
#         }
#       }
#     }
#
# @model GradeGroup
#     {
#       "id": "GradeGroup",
#       "properties": {
#         "submission_id": {
#            "$ref": "AssignmentGroupGrade"
#         }
#       }
#     }
#
# @model Grades
#     {
#       "id": "Grades",
#       "properties": {
#         "current": {
#            "$ref": "Grade"
#         },
#         "current_groups": {
#            "$ref": "GradeGroup"
#         },
#         "final": {
#            "$ref": "Grade"
#         },
#         "final_groups": {
#            "$ref": "GradeGroup"
#         }
#       }
#     }
#
# @model Submission
#     {
#       "id": "Submission",
#       "properties": {
#         "id": {
#           "description": "The ID of the submission",
#           "example": 123,
#           "type": "integer"
#         },
#         "student_entered_score": {
#           "description": "The score the student wants to test",
#           "example": "20.0",
#           "type": "string"
#         }
#       }
#     }
#

class WhatIfGradesApiController < ApplicationController
  include SubmissionsHelper
  before_action :require_user

  # @API Update a submission's what-if score and calculate grades
  # Enter a what if score for a submission and receive the calculated grades
  # Grade calculation is a costly operation, so this API should be used sparingly
  #
  # @argument student_entered_score [Float]
  #  The score the student wants to test
  #
  # @example_response
  #   {
  #       "grades": [
  #           {
  #               "current": {
  #                   "grade": 120.0,
  #                   "total": 24.0,
  #                   "possible": 20.0,
  #                   "dropped": []
  #               },
  #               "current_groups": {
  #                   "1": {
  #                       "id": 1,
  #                       "global_id": 10000000000001,
  #                       "score": 20.0,
  #                       "possible": 10.0,
  #                       "weight": 0.0,
  #                       "grade": 200.0,
  #                       "dropped": []
  #                   },
  #                   "3": {
  #                       "id": 3,
  #                       "global_id": 10000000000003,
  #                       "score": 4.0,
  #                       "possible": 10.0,
  #                       "weight": 0.0,
  #                       "grade": 40.0,
  #                       "dropped": []
  #                   }
  #               },
  #               "final": {
  #                   "grade": 21.82,
  #                   "total": 24.0,
  #                   "possible": 110.0,
  #                   "dropped": []
  #               },
  #               "final_groups": {
  #                   "1": {
  #                       "id": 1,
  #                       "global_id": 10000000000001,
  #                       "score": 20.0,
  #                       "possible": 100.0,
  #                       "weight": 0.0,
  #                       "grade": 20.0,
  #                       "dropped": []
  #                   },
  #                   "3": {
  #                       "id": 3,
  #                       "global_id": 10000000000003,
  #                       "score": 4.0,
  #                       "possible": 10.0,
  #                       "weight": 0.0,
  #                       "grade": 40.0,
  #                       "dropped": []
  #                   }
  #               }
  #           }
  #       ],
  #       "submission": {
  #           "id": 166,
  #           "student_entered_score": 20.0
  #       }
  #   }
  #
  # @returns {"grades": [Grades], "submission": Submission}
  def update
    submission = @current_user.submissions.find(params[:id])
    return render_unauthorized_action unless submission.grants_right?(@current_user, :submit)

    respond_to do |format|
      format.json do
        student_entered_score = params[:student_entered_score]

        if !params.key?(:student_entered_score) || !validate_student_entered_score(student_entered_score)
          return render json: { error: "student_entered_score is required to be either a number or null." }, status: :bad_request
        end

        what_if_grade = sanitize_student_entered_score(student_entered_score)
        begin
          grades = Submissions::WhatIfGradesService.new(@current_user).update(submission, what_if_grade)
          render json: { grades:, submission: { id: submission.id, student_entered_score: submission.student_entered_score } }
        rescue
          render json: submission.errors, status: :bad_request
        end
      end
    end
  end

  # @API Reset the what-if scores for the current user for an entire course and recalculate grades
  #
  # @returns {"grades": [Grades]}
  def reset_for_student_course
    course = @domain_root_account.all_courses.active.find(params[:course_id])
    return render_unauthorized_action unless course.grants_right?(@current_user, :reset_what_if_grades)

    grades = Submissions::WhatIfGradesService.new(@current_user).reset_for_course(course)

    respond_to do |format|
      format.json do
        render json: { grades: }
      end
    end
  end

  private

  def validate_student_entered_score(score)
    return true if score.nil? || ["null", "nil"].include?(score)

    begin
      !!Float(score)
    rescue
      false
    end
  end
end

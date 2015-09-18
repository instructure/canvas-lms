#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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

# @API Moderated Grading
# @subtopic Provisional Grades
# @beta
#
# API for manipulating provisional grades
#
# Provisional grades are created by using the Submissions API endpoint "Grade or comment on a submission" with `provisional=true`.
# They can be viewed by using "List assignment submissions" or "Get a single submission" with `include[]=provisional_grades`.
# This API performs other operations on provisional grades for use with the Moderated Grading feature.
#
# @model ProvisionalGrade
#     {
#       "id": "ProvisionalGrade",
#       "description": "",
#       "properties": {
#         "provisional_grade_id": {
#           "description": "The identifier for the provisional grade",
#           "example": 23,
#           "type": "integer"
#         },
#         "score": {
#           "description": "The numeric score",
#           "example": 90,
#           "type": "integer"
#         },
#         "grade": {
#           "description": "The grade",
#           "example": "A-",
#           "type": "string"
#         },
#         "grade_matches_current_submission": {
#           "description": "Whether the grade was applied to the most current submission (false if the student resubmitted after grading)",
#           "example": true,
#           "type": "boolean"
#         },
#         "graded_at": {
#           "description": "When the grade was given",
#           "example": "2015-11-01T00:03:21-06:00",
#           "type": "datetime"
#         },
#         "final": {
#           "description": "Whether this is the 'final' provisional grade created by the moderator",
#           "example": false,
#           "type": "boolean"
#         },
#         "speedgrader_url": {
#           "description": "A link to view this provisional grade in SpeedGrader™",
#           "example": "http://www.example.com/courses/123/gradebook/speed_grader?...",
#           "type": "string"
#         }
#       }
#     }
class ProvisionalGradesController < ApplicationController
  before_filter :require_user
  before_filter :load_assignment

  include Api::V1::Submission

  # @API Copy provisional grade
  #
  # Given a provisional grade, copy the grade (and associated submission comments and rubric assessments)
  # to a "final" mark which can be edited or commented upon by a moderator prior to publication of grades.
  #
  # Notes:
  # * The student must be in the moderation set for the assignment.
  # * The newly created grade will be selected.
  # * The caller must have "Moderate Grades" rights in the course.
  #
  # @returns ProvisionalGrade
  def copy_to_final_mark
    if authorized_action @context, @current_user, :moderate_grades
      pg = @assignment.provisional_grades.find(params[:provisional_grade_id])
      return render :json => { :message => 'provisional grade is already final' }, :status => :bad_request if pg.final
      selection = @assignment.moderated_grading_selections.where(student_id: pg.submission.user_id).first
      return render :json => { :message => 'student not in moderation set' }, :status => :bad_request unless selection
      final_mark = pg.copy_to_final_mark!(@current_user)
      selection.provisional_grade = final_mark
      selection.save!
      render :json => provisional_grade_json(final_mark, pg.submission, @assignment, @current_user, %w(submission_comments rubric_assessment))
    end
  end

  private

  def load_assignment
    @context = api_find(Course, params[:course_id])
    @assignment = @context.assignments.find(params[:assignment_id])
  end
end
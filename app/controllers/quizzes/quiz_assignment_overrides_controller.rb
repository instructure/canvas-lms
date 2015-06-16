#
# Copyright (C) 2012 Instructure, Inc.
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

# @API Quiz Assignment Overrides
#
# @model QuizAssignmentOverrideSet
#     {
#       "id": "QuizAssignmentOverrideSet",
#       "description": "Set of assignment-overridden dates for a quiz.",
#       "properties": {
#         "quiz_id": {
#           "description": "ID of the quiz those dates are for.",
#           "example": "1",
#           "type": "string"
#         },
#         "due_dates": {
#           "description": "An array of quiz assignment overrides. For students, this array will always contain a single item which is the set of dates that apply to that student. For teachers and staff, it may contain more.",
#           "$ref": "QuizAssignmentOverride"
#         },
#         "all_dates": {
#           "description": "An array of all assignment overrides active for the quiz. This is visible only to teachers and staff.",
#           "$ref": "QuizAssignmentOverride"
#         }
#       }
#     }
#
# @model QuizAssignmentOverrideSetContainer
#     {
#       "id": "QuizAssignmentOverrideSetContainer",
#       "description": "Container for set of assignment-overridden dates for a quiz.",
#       "properties": {
#         "quiz_assignment_overrides": {
#           "description": "The QuizAssignmentOverrideSet",
#           "type": "array",
#           "items": {
#             "$ref": "QuizAssignmentOverrideSet"
#           }
#         }
#       }
#     }
#
# @model QuizAssignmentOverride
#     {
#       "id": "QuizAssignmentOverride",
#       "description": "Set of assignment-overridden dates for a quiz.",
#       "properties": {
#         "id": {
#           "type": "integer",
#           "example": 1,
#           "description": "ID of the assignment override, unless this is the base construct, in which case the 'id' field is omitted."
#         },
#         "due_at": {
#           "description": "The date after which any quiz submission is considered late.",
#           "example": "2014-02-21T06:59:59Z",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "description": "Date when the quiz becomes available for taking.",
#           "example": null,
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "When the quiz will stop being available for taking. A value of null means it can always be taken.",
#           "example": "2014-02-21T06:59:59Z",
#           "type": "datetime"
#         },
#         "title": {
#           "description": "Title of the section this assignment override is for, if any.",
#           "example": "Project X",
#           "type": "string"
#         },
#         "base": {
#           "description": "If this property is present, it means that dates in this structure are not based on an assignment override, but are instead for all students.",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
class Quizzes::QuizAssignmentOverridesController < ApplicationController
  include Filters::Quizzes

  before_filter :require_course, only: [ :index ]
  skip_around_filter :set_locale, only: [ :index ]

  # @API Retrieve assignment-overridden dates for quizzes
  # @beta
  #
  # Retrieve the actual due-at, unlock-at, and available-at dates for quizzes
  # based on the assignment overrides active for the current API user.
  #
  # @argument quiz_assignment_overrides[0][quiz_ids][] [Optional, Integer|String]
  #   An array of quiz IDs. If omitted, overrides for all quizzes available to
  #   the operating user will be returned.
  #
  # @example_response
  #     {
  #        "quiz_assignment_overrides": [{
  #          "quiz_id": "1",
  #          "due_dates": [QuizAssignmentOverride],
  #          "all_dates": [QuizAssignmentOverride]
  #        },{
  #          "quiz_id": "2",
  #          "due_dates": [QuizAssignmentOverride],
  #          "all_dates": [QuizAssignmentOverride]
  #        }]
  #     }
  #
  # @returns QuizAssignmentOverrideSetContainer
  def index
    can_manage = @course.grants_right?(@current_user, session, :manage_assignments)

    api_route = api_v1_course_quiz_assignment_overrides_url(@course)
    quiz_ids = (Array(params[:quiz_assignment_overrides])[0] || {})[:quiz_ids]

    scope = @course.quizzes.active.includes([ :assignment ])
    scope = scope.where(id: quiz_ids) if quiz_ids.present?
    scope = scope.available unless can_manage

    if @course.feature_enabled?(:differentiated_assignments)
      scope = DifferentiableAssignment.scope_filter(scope, @current_user, @course)
    end

    quizzes = Api.paginate(scope, self, api_route)

    render({
      json: {
        quiz_assignment_overrides: quizzes.map do |quiz|
          serialize_overrides(quiz, @current_user, can_manage)
        end
      }
    })
  end

  private

  def serialize_overrides(quiz, user, include_all_dates)
    {}.tap do |quiz_overrides|
      quiz_overrides[:quiz_id] = quiz.id
      quiz_overrides[:due_dates] = quiz.dates_hash_visible_to(user)

      if include_all_dates
        quiz_overrides[:all_dates] = quiz.formatted_dates_hash(quiz.all_due_dates)
      end
    end
  end
end

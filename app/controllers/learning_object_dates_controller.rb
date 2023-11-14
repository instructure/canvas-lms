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
#

# @API Learning Object Dates
#
# API for accessing date-related attributes on assignments, quizzes, and modules.
#
# @model LearningObjectDates
#     {
#       "id": "LearningObjectDates",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the learning object",
#           "example": 4,
#           "type": "integer"
#         },
#         "due_at": {
#           "description": "the due date for the learning object. returns null if not present or applicable",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "the lock date (learning object is locked after this date). returns null if not present",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "description": "the unlock date (learning object is unlocked after this date). returns null if not present",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "only_visible_to_overrides": {
#           "description": "whether the learning object is only visible to overrides",
#           "example": false,
#           "type": "boolean"
#         },
#         "overrides": {
#           "description": "paginated list of AssignmentOverride objects",
#           "type": "array",
#           "items": { "$ref": "AssignmentOverride" }
#         }
#       }
#     }
class LearningObjectDatesController < ApplicationController
  before_action :require_feature_flag # remove when differentiated_modules flag is removed
  before_action :require_user
  before_action :require_context
  before_action :check_authorized_action

  include Api::V1::LearningObjectDates
  include Api::V1::Assignment
  include Api::V1::AssignmentOverride

  # @API Get a learning object's date information
  #
  # Get a learning object's date-related information, including due date, availability dates,
  # override status, and a paginated list of all assignment overrides for the item.
  #
  # Note: this API is still under development and will not function until the feature is enabled.
  #
  # @returns LearningObjectDates
  def show
    route = polymorphic_url([:api_v1, @context, asset, :date_details])
    overrides = Api.paginate(asset.all_assignment_overrides.active, self, route)
    render json: {
      **learning_object_dates_json(asset, @current_user, session),
      overrides: assignment_overrides_json(overrides, @current_user, include_names: true)
    }
  end

  # @API Update a learning object's date information
  #
  # Updates date-related information for learning objects, including due date, availability dates,
  # override status, and assignment overrides.
  #
  # Returns 204 No Content response code if successful.
  #
  # Note: this API is still under development and will not function until the feature is enabled.
  #
  # @argument due_at [DateTime]
  #   The learning object's due date.
  #
  # @argument unlock_at [DateTime]
  #   The learning object's unlock date. Must be before the due date if there is one.
  #
  # @argument lock_at [DateTime]
  #   The learning object's lock date. Must be after the due date if there is one.
  #
  # @argument only_visible_to_overrides [Boolean]
  #   Whether the learning object is only assigned to students who are targeted by an override.
  #
  # @argument assignment_overrides[] [Array]
  #   List of overrides to apply to the learning object. Overrides that already exist should include
  #   an ID and will be updated if needed. New overrides will be created for overrides in the list
  #   without an ID. Overrides not included in the list will be deleted. Providing an empty list
  #   will delete all of the object's overrides. Keys for each override object can include: 'id',
  #   'title', 'student_ids', and 'course_section_id'.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/assignments/:assignment_id/date_details \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -H 'Content-Type: application/json' \
  #     -d '{
  #           "due_at": "2012-07-01T23:59:00-06:00",
  #           "unlock_at": "2012-06-01T00:00:00-06:00",
  #           "lock_at": "2012-08-01T00:00:00-06:00",
  #           "only_visible_to_overrides": true,
  #           "assignment_overrides": [
  #             {
  #               "id": 212,
  #               "course_section_id": 3564
  #             },
  #             {
  #               "title": "an assignment override",
  #               "student_ids": [1, 2, 3]
  #             }
  #           ]
  #         }'
  def update
    case asset.class_name
    when "Assignment"
      update_assignment(asset, object_update_params)
    when "Quizzes::Quiz"
      update_quiz(asset, object_update_params)
    end
  end

  private

  def require_feature_flag
    not_found unless Account.site_admin.feature_enabled? :differentiated_modules
  end

  def check_authorized_action
    render_unauthorized_action unless @context.grants_any_right?(@current_user, :manage_content, :manage_course_content_edit)
  end

  def asset
    @asset ||= if params[:assignment_id]
                 @context.active_assignments.find(params[:assignment_id])
               elsif params[:quiz_id]
                 @context.active_quizzes.find(params[:quiz_id])
               elsif params[:context_module_id]
                 @context.context_modules.not_deleted.find(params[:context_module_id])
               end
  end

  def update_assignment(assignment, params)
    assignment.updating_user = @current_user
    result = update_api_assignment(assignment, params, @current_user)
    return head :no_content if [:created, :ok].include?(result)

    render json: assignment.errors, status: (result == :forbidden) ? :forbidden : :bad_request
  end

  def update_quiz(quiz, params)
    return render json: quiz.errors, status: :forbidden unless grading_periods_allow_submittable_update?(quiz, params)

    overrides = params.delete :assignment_overrides
    if overrides
      batch = prepare_assignment_overrides_for_batch_update(quiz, overrides, @current_user)
      return render json: quiz.errors, status: :forbidden unless grading_periods_allow_assignment_overrides_batch_update?(quiz, batch)

      quiz.assignment&.validate_overrides_for_sis(overrides)
    end

    Assignment.suspend_due_date_caching do
      quiz.transaction do
        quiz.update!(params)
        perform_batch_update_assignment_overrides(quiz, batch) if overrides
      end
    end

    if quiz.assignment
      quiz.assignment.clear_cache_key(:availability)
      SubmissionLifecycleManager.recompute(quiz.assignment, update_grades: true, executing_user: @current_user)
    end

    head :no_content
  end

  def object_update_params
    params.permit(:due_at,
                  :unlock_at,
                  :lock_at,
                  :only_visible_to_overrides,
                  assignment_overrides: strong_anything)
  end
end

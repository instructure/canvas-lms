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
    overrides = Api.paginate(asset.assignment_overrides.active, self, route)
    render json: {
      **learning_object_dates_json(asset, @current_user, session),
      overrides: assignment_overrides_json(overrides, @current_user, include_student_names: true)
    }
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
end

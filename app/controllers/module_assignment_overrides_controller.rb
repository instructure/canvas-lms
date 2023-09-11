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

# @API Modules
# @subtopic Module Assignment Overrides
#
# If any active AssignmentOverrides exist on a ContextModule, then only students who have an
# applicable override can access the module and are assigned its items. AssignmentOverrides can
# be created for a (group of) student(s) or a section. *This module overrides feature is still
# under development and is not yet enabled.*
#
# @model ModuleAssignmentOverride
#     {
#       "id": "ModuleAssignmentOverride",
#       "properties": {
#         "id": {
#           "description": "the ID of the assignment override",
#           "example": 4355,
#           "type": "integer"
#         },
#         "context_module_id": {
#           "description": "the ID of the module the override applies to",
#           "example": 567,
#           "type": "integer"
#         },
#         "title": {
#           "description": "the title of the override",
#           "example": "Section 6",
#           "type": "string"
#         },
#         "students": {
#           "description": "an array of the override's target students (present only if the override targets an adhoc set of students)",
#           "$ref": "OverrideTarget"
#         },
#         "course_section": {
#           "description": "the override's target section (present only if the override targets a section)",
#           "$ref": "OverrideTarget"
#         }
#       }
#     }
#
# @model OverrideTarget
#     {
#       "id": "OverrideTarget",
#       "properties": {
#         "id": {
#           "description": "the ID of the user or section that the override is targeting",
#           "example": 7,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the name of the user or section that the override is targeting",
#           "example": "Section 6",
#           "type": "string"
#         }
#       }
#     }
class ModuleAssignmentOverridesController < ApplicationController
  include Api::V1::ModuleAssignmentOverride

  before_action :require_feature_flag # remove when differentiated_modules flag is removed
  before_action :require_user
  before_action :require_context
  before_action :check_authorized_action
  before_action :require_context_module

  # @API List a module's overrides
  #
  # Returns a paginated list of AssignmentOverrides that apply to the ContextModule.
  #
  # Note: this API is still under development and will not function until the feature is enabled.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/modules/:context_module_id/assignment_overrides \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns [ModuleAssignmentOverride]
  def index
    GuardRail.activate(:secondary) do
      overrides = @context_module.assignment_overrides.active
      paginated_overrides = Api.paginate(overrides, self, api_v1_module_assignment_overrides_index_url)
      render json: module_assignment_overrides_json(paginated_overrides, @current_user)
    end
  end

  private

  def require_feature_flag
    not_found unless Account.site_admin.feature_enabled? :differentiated_modules
  end

  def check_authorized_action
    render_unauthorized_action unless @context.grants_any_right?(@current_user, :manage_content, :manage_course_content_edit)
  end

  def require_context_module
    @context_module = @context.context_modules.not_deleted.find(params[:context_module_id])
  end
end

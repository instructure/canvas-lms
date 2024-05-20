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

  # @API Update a module's overrides
  #
  # Accepts a list of overrides and applies them to the ContextModule. Returns 204 No Content response
  # code if successful.
  #
  # Note: this API is still under development and will not function until the feature is enabled.
  #
  # @argument overrides[] [Required, Array]
  #   List of overrides to apply to the module. Overrides that already exist should include an ID
  #   and will be updated if needed. New overrides will be created for overrides in the list
  #   without an ID. Overrides not included in the list will be deleted. Providing an empty list
  #   will delete all of the module's overrides. Keys for each override object can include: 'id',
  #   'title', 'student_ids', and 'course_section_id'.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/modules/:context_module_id/assignment_overrides \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -H 'Content-Type: application/json' \
  #     -d '{
  #           "overrides": [
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
  #
  def bulk_update
    override_list = params[:overrides] || []
    return render json: { error: "List of overrides required" }, status: :bad_request unless override_list.is_a?(Array)

    override_list.each do |override|
      unless override["id"].present? || override["student_ids"].present? || override["course_section_id"].present?
        return render json: { error: "id, student_ids, or course_section_id required with each override" }, status: :bad_request
      end
      if override["course_section_id"].present? && override["student_ids"].present?
        return render json: { error: "cannot provide course_section_id and student_ids on the same override" }, status: :bad_request
      end
    end

    bulk_update_overrides(override_list)
    head :no_content
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

  def bulk_update_overrides(override_list)
    overrides_to_update, overrides_to_create = override_list.partition { |override| override["id"].present? }
    override_ids_to_delete = @context_module.assignment_overrides.active.pluck(:id) - overrides_to_update.pluck("id").map(&:to_i)

    AssignmentOverride.transaction do
      delete_existing_overrides(override_ids_to_delete)
      update_existing_overrides(overrides_to_update)
      create_new_overrides(overrides_to_create)
      @context_module.update_assignment_submissions
    end
  end

  def delete_existing_overrides(override_ids)
    @context_module.assignment_override_students.where(assignment_override_id: override_ids).delete_all
    @context_module.assignment_overrides.active.where(id: override_ids).destroy_all
  end

  def update_existing_overrides(overrides)
    overrides.each do |override|
      current_override = @context_module.assignment_overrides.active.find(override["id"])
      current_override.title = override["title"] if override["title"].present?
      if override["course_section_id"].present?
        current_override.assignment_override_students.delete_all if current_override.set_type == "ADHOC"
        current_override.course_section = @context.course_sections.find(override["course_section_id"])
      elsif override["student_ids"].present?
        if current_override.set_type == "ADHOC"
          user_ids_to_delete = current_override.assignment_override_students.pluck(:user_id) - override["student_ids"].map(&:to_i)
          current_override.assignment_override_students.where(user_id: user_ids_to_delete).delete_all
        else
          current_override.set_type = "ADHOC"
          current_override.set_id = nil
        end
        existing_user_ids = current_override.assignment_override_students.pluck(:user_id)
        override["student_ids"].map(&:to_i).each do |student_id|
          current_override.assignment_override_students.create!(user: @context.students.find(student_id)) unless existing_user_ids.include?(student_id)
        end
      end
      current_override.save!
    end
  end

  def create_new_overrides(overrides)
    overrides.each do |override|
      new_override = @context_module.assignment_overrides.build
      new_override.title = override["title"] if override["title"].present?
      if override["course_section_id"].present?
        new_override.course_section = @context.course_sections.find(override["course_section_id"])
      elsif override["student_ids"].present?
        override["student_ids"].each { |student_id| new_override.assignment_override_students.build(user: @context.students.find(student_id)) }
      end
      new_override.save!
    end
  end
end

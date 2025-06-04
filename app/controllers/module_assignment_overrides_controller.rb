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
# be created for a (group of) student(s) or a section.
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
  include DifferentiationTag

  before_action :require_user
  before_action :require_context
  before_action :check_authorized_action
  before_action :require_context_module

  # @API List a module's overrides
  #
  # Returns a paginated list of AssignmentOverrides that apply to the ContextModule.
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
  # @argument overrides[] [Required, Array]
  #   List of overrides to apply to the module. Overrides that already exist should include an ID
  #   and will be updated if needed. New overrides will be created for overrides in the list
  #   without an ID. Overrides not included in the list will be deleted. Providing an empty list
  #   will delete all of the module's overrides. Keys for each override object can include: 'id',
  #   'title', 'student_ids', and 'course_section_id'. 'group_id' is accepted if the Differentiation
  #   Tags account setting is enabled.
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
  #               "id": 56,
  #               "group_id": 7809
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
      if @context.account.allow_assign_to_differentiation_tags? && override["group_id"].present?
        if override["student_ids"].present? && override["course_section_id"].present?
          return render json: { error: "cannot provide group_id, course_section_id, and student_ids on the same override" }, status: :bad_request
        elsif override["course_section_id"].present?
          return render json: { error: "cannot provide group_id and course_section_id on the same override" }, status: :bad_request
        elsif override["student_ids"].present?
          return render json: { error: "cannot provide group_id and student_ids on the same override" }, status: :bad_request
        end
      elsif override["group_id"].present?
        return render json: { error: "group_id is not allowed as an override" }, status: :bad_request
      end

      required_params = %w[id student_ids course_section_id]
      required_params << "group_id" if @context.account.allow_assign_to_differentiation_tags?
      unless required_params.any? { |param| override[param].present? }
        return render json: { error: "#{[required_params[0...-1].join(", "), required_params.last].join(", or ")} required with each override" }, status: :bad_request
      end

      if override["course_section_id"].present? && override["student_ids"].present?
        return render json: { error: "cannot provide course_section_id and student_ids on the same override" }, status: :bad_request
      end
    end

    bulk_update_overrides(override_list)
    head :no_content
  end

  def convert_tag_overrides_to_adhoc_overrides
    errors = OverrideConverterService.convert_tags_to_adhoc_overrides_for(
      learning_object: @context_module,
      course: @context
    )

    if errors
      return render json: { errors: }, status: :bad_request
    end

    head :no_content
  end

  private

  def check_authorized_action
    render_unauthorized_action unless @context.grants_right?(@current_user, :manage_course_content_edit)
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
      @context_module.touch_context
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
      elsif override["group_id"].present? && @context.account.allow_assign_to_differentiation_tags?
        group = find_group(override["group_id"])
        current_override.group = group if group.non_collaborative?
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
      elsif override["group_id"].present? && @context.account.allow_assign_to_differentiation_tags?
        group = find_group(override["group_id"])
        new_override.group = group if group.non_collaborative?
      elsif override["student_ids"].present?
        override["student_ids"].each { |student_id| new_override.assignment_override_students.build(user: @context.students.find(student_id)) }
      end
      new_override.save!
    end
  end

  def find_group(group_id)
    Group.non_collaborative.find_by(context: @context, id: group_id)
  end
end

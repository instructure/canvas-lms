# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Mutations::SetModuleItemCompletion < Mutations::BaseMutation
  include PlannerApiHelper

  graphql_name "SetModuleItemCompletion"

  argument :module_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("ContextModule")
  argument :item_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("ContextModuleItem")
  argument :done, Boolean, required: true

  field :module_item, Types::ModuleItemType, null: false

  def resolve(input:)
    context_module = ContextModule.find(input[:module_id])
    course = context_module.context

    verify_authorized_action!(course, :read)

    unless course.modules_visible_to(current_user).include?(context_module)
      raise GraphQL::ExecutionError, "not found"
    end

    module_item = context_module.content_tags.find(input[:item_id])
    if input[:done]
      module_item.context_module_action(current_user, :done)
    else
      progression = module_item.progression_for_user(current_user)
      raise GraphQL::ExecutionError, "not found" if progression.blank?

      progression.uncomplete_requirement(module_item.id)
      progression.evaluate
    end
    sync_planner_completion(module_item.content, current_user, input[:done]) if planner_enabled?

    { module_item: }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end

  private

  def planner_enabled?
    current_user.present? && current_user.has_student_enrollment?
  end
end

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

class Mutations::UpdateLearningOutcomeGroup < Mutations::BaseMutation
  graphql_name "UpdateLearningOutcomeGroup"

  argument :id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("LearningOutcomeGroup")
  argument :title, String, required: false
  argument :description, String, required: false
  argument :vendor_guid, String, required: false
  argument :parent_outcome_group_id, ID, required: false

  field :learning_outcome_group, Types::LearningOutcomeGroupType, null: true

  def resolve(input:)
    @outcome_group = get_group(input[:id])

    check_user_permissions

    if @outcome_group.update(attributes(input))
      if input[:parent_outcome_group_id] && input[:parent_outcome_group_id] != @outcome_group.learning_outcome_group_id
        new_parent_group = get_parent_group(input[:parent_outcome_group_id])
        raise GraphQL::ExecutionError, I18n.t("Could not update parent group") unless new_parent_group.adopt_outcome_group(@outcome_group)
      end
      { learning_outcome_group: @outcome_group }
    else
      errors_for(@outcome_group)
    end
  end

  private

  def get_group(id)
    LearningOutcomeGroup.active.find_by(id:).tap do |group|
      raise GraphQL::ExecutionError, I18n.t("Group not found") unless group
    end
  end

  def get_parent_group(id)
    LearningOutcomeGroup.for_context(@outcome_group.context).active.find_by(id:).tap do |group|
      raise GraphQL::ExecutionError, I18n.t("Parent group not found in this context") unless group
    end
  end

  def check_user_permissions
    raise GraphQL::ExecutionError, I18n.t("Insufficient permissions") unless can_manage_outcomes
  end

  def can_manage_outcomes
    if @outcome_group.context
      @outcome_group.context.grants_right?(current_user, session, :manage_outcomes)
    else
      Account.site_admin.grants_right?(current_user, session, :manage_global_outcomes)
    end
  end

  def attributes(input)
    input.to_h.slice(:title, :description, :vendor_guid)
  end
end

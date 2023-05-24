# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
module Types
  class LearningOutcomeGroupType < ApplicationObjectType
    description "Learning Outcome Group"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :parent_outcome_group, Types::LearningOutcomeGroupType, null: true
    field :child_groups,
          Types::LearningOutcomeGroupType.connection_type,
          null: true
    def child_groups
      active_child_groups
    end

    field :context_id, ID, null: true
    field :context_type, String, null: true
    field :title, String, null: false
    field :description, String, null: true
    field :vendor_guid, String, null: true

    field :can_edit, Boolean, null: false
    def can_edit
      if object.context_id
        return object.context.grants_right?(current_user, session, :manage_outcomes)
      end

      Account.site_admin.grants_right?(current_user, session, :manage_global_outcomes)
    end

    field :child_groups_count, Integer, null: false
    def child_groups_count
      active_child_groups.size
    end

    field :outcomes_count, Integer, null: false do
      argument :search_query, String, required: false
    end
    def outcomes_count(**args)
      learning_outcome_group_children_service.total_outcomes(object.id, args)
    end

    field :not_imported_outcomes_count, Integer, null: true do
      argument :target_group_id, ID, required: false
    end
    def not_imported_outcomes_count(**args)
      learning_outcome_group_children_service.not_imported_outcomes(object.id, args)
    end

    field :outcomes, Types::ContentTagConnection, null: false do
      argument :search_query, String, required: false
      argument :filter, String, required: false
    end
    def outcomes(**args)
      learning_outcome_group_children_service.suboutcomes_by_group_id(object.id, args)
    end

    private

    def learning_outcome_group_children_service
      @learning_outcome_group_children_service ||= Outcomes::LearningOutcomeGroupChildren.new(object.context)
    end

    def active_child_groups
      @active_child_groups ||= object.child_outcome_groups.active
    end
  end
end

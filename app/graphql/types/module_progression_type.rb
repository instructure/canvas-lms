# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
  class ModuleProgressionType < ApplicationObjectType
    graphql_name "ModuleProgression"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    alias_method :context_module_progression, :object

    global_id_field :id

    field :collapsed, Boolean, null: true
    field :completed_at, DateTimeType, null: true
    field :current_position, Integer, null: true
    field :workflow_state, String, null: false

    class RequirementType < ApplicationObjectType
      field :id, ID, null: false
      field :min_percentage, Float, null: true
      field :min_score, Float, null: true
      field :score, Float, null: true
      field :type, String, null: false
    end

    field :requirements_met, [RequirementType], null: true
    def requirements_met
      (context_module_progression.requirements_met || []).map do |req|
        req.is_a?(Hash) ? req.with_indifferent_access : { id: nil, type: req.to_s }
      end
    end

    field :incomplete_requirements, [RequirementType], null: true
    def incomplete_requirements
      (context_module_progression.incomplete_requirements || []).map do |req|
        req.is_a?(Hash) ? req.with_indifferent_access : { id: nil, type: req.to_s }
      end
    end

    field :current, Boolean, null: true
    field :evaluated_at, DateTimeType, null: true

    field :context_module, Types::ModuleType, null: true, resolver_method: :context_module_resolver
    def context_module_resolver
      load_association(:context_module)
    end

    field :user, Types::UserType, null: true, resolver_method: :user_resolver
    def user_resolver
      load_association(:user)
    end

    field :completed, Boolean, null: false, method: :completed?
    field :locked, Boolean, null: false, method: :locked?
    field :started, Boolean, null: false, method: :started?
    field :unlocked, Boolean, null: false, method: :unlocked?
  end
end

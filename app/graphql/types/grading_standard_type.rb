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

module Types
  class GradingStandardItemType < ApplicationObjectType
    graphql_name "GradingStandardItem"

    field :letter_grade, String, null: true
    def letter_grade
      object[0]
    end

    field :base_value, Float, null: true
    def base_value
      object[1]
    end
  end

  class GradingStandardType < ApplicationObjectType
    graphql_name "GradingStandard"

    implements GraphQL::Types::Relay::Node

    global_id_field :id
    # This field _id allows null because the default gradingStandard has a nil id
    field :_id, ID, "legacy canvas id", method: :id, null: true

    field :context_id, ID, null: true
    field :context_code, String, null: true
    field :context_type, String, null: true

    field :created_at, DateTimeType, null: true
    field :updated_at, DateTimeType, null: true

    field :data, [GradingStandardItemType], null: true

    field :migration_id, ID, null: true

    field :root_account_id, ID, null: true

    field :title, String, null: true

    field :usage_count, Integer, null: true

    field :user_id, ID, null: true

    field :version, Integer, null: true

    field :workflow_state, String, null: true
  end
end

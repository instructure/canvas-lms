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
  class AllocationRuleType < ApplicationObjectType
    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    alias_method :allocation_rule, :object

    global_id_field :id

    field :must_review,
          Boolean,
          "Boolean indicating if the assessor must review the assessee",
          null: false

    field :review_permitted,
          Boolean,
          "Boolean indicating if the assessor is permitted to review the assessee",
          null: false

    field :applies_to_assessor,
          Boolean,
          "Boolean indicating if this rule applies to the assessor (true) or assessee (false)",
          null: false

    field :workflow_state,
          String,
          "The current state of the allocation rule",
          null: false

    field :assessor,
          UserType,
          "The user who will be doing the peer review",
          null: true
    def assessor
      return unless object.assignment.grants_right?(current_user, :grade)

      load_association(:assessor)
    end

    field :assessee,
          UserType,
          "The user who will be receiving the peer review",
          null: true
    def assessee
      return unless object.assignment.grants_right?(current_user, :grade)

      load_association(:assessee)
    end

    field :assignment_id, ID, null: false
    field :course_id, ID, null: false
  end
end

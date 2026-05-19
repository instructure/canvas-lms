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
  class RubricAssociationType < ApplicationObjectType
    description "How a rubric is being used in a context"

    implements Interfaces::LegacyIDInterface

    field :association_id, String, null: false
    field :association_type, String, null: false

    field :hide_outcome_results, Boolean, null: false
    def hide_outcome_results
      !!object.hide_outcome_results
    end

    field :hide_points, Boolean, null: false do
      argument :check_extra_permissions,
               Boolean,
               required: false,
               default_value: false,
               description: "used for additional permissions checks if restrict_quantitative_data is enabled"
    end
    def hide_points(check_extra_permissions: false)
      !!object.hide_points(current_user, check_extra_permissions:)
    end

    field :hide_score_total, Boolean, null: false
    def hide_score_total
      !!object.hide_score_total
    end

    field :use_for_grading, Boolean, null: false
    def use_for_grading
      !!object.use_for_grading
    end
    field :saved_comments, String, null: true
    def saved_comments
      object.summary_data&.dig(:saved_comments)&.to_json
    end
  end
end

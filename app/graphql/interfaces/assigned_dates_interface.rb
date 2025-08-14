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

module Interfaces
  module AssignedDatesInterface
    include Interfaces::BaseInterface

    graphql_name "AssignedDates"

    description "Contains standardized date hash information for objects with date overrides"

    field :assigned_to_dates,
          [Types::DateHashType],
          null: true,
          description: "Standardized date hash visible to current user (when feature flag enabled)"

    def assigned_to_dates
      return nil unless Account.site_admin.feature_enabled?(:standardize_assignment_date_formatting)

      # For graded discussions, use the assignment's dates; for ungraded discussions, return nil
      if object.is_a?(DiscussionTopic)
        return nil unless object.graded?

        return Loaders::DatesOverridableLoader.for.load(object.assignment).then do |preloaded_assignment|
          preloaded_assignment&.dates_hash_visible_to_v2(current_user)
        end
      end

      Loaders::DatesOverridableLoader.for.load(object).then do |preloaded_object|
        preloaded_object.dates_hash_visible_to_v2(current_user)
      end
    end
  end
end

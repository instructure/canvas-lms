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
  class ModuleStatisticsType < ApplicationObjectType
    graphql_name "ModuleStatistics"

    alias_method :submissions, :object

    field :missing_assignment_count, Integer, null: false
    def missing_assignment_count
      return 0 unless current_user

      submissions.count(&:missing?)
    end

    field :latest_due_at, GraphQL::Types::ISO8601DateTime, null: true
    def latest_due_at
      return nil unless current_user

      submissions.filter_map(&:cached_due_date).max
    end
  end
end

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

module Loaders
  module UserLoaders
    class GroupMembershipsLoader < GraphQL::Batch::Loader
      # This loader handles fetching group memberships for multiple users efficiently
      # and supports filtering by state, group state, and group course ID.

      def self.for(filter: {})
        # Create a consistent string key by sorting the filter hash entries
        key = filter.to_h.sort.map { |k, v| "#{k}:#{v}" }.join(";")

        @loaders ||= {}
        @loaders[key] ||= new(filter:)
      end

      def initialize(filter: {})
        super()
        @filter = filter
      end

      def perform(user_ids)
        scope = GroupMembership.where(user_id: user_ids)

        # Apply filters
        if @filter[:group_course_id].present? || @filter[:group_state].present?
          scope = scope.joins(:group)
          scope = scope.where(groups: { workflow_state: @filter[:group_state] }) if @filter[:group_state].present?
          scope = scope.where(groups: { context_id: @filter[:group_course_id] }) if @filter[:group_course_id].present?
        end

        scope = scope.where(workflow_state: @filter[:state]) if @filter[:state].present?

        # Group results by user_id for efficient lookup
        memberships_by_user_id = scope.group_by(&:user_id)

        # Fulfill requests for each user_id
        user_ids.each do |user_id|
          fulfill(user_id, memberships_by_user_id[user_id] || [])
        end
      end
    end
  end
end

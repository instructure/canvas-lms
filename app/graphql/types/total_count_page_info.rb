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
  # TotalCountPageInfo extends the standard Relay PageInfo to add total count metadata.
  #
  # This provides the total count of items in a connection, regardless of pagination limits.
  # The count respects all filtering, grouping, and business logic from the original query
  # while removing only pagination-specific scopes (limit, offset, order).
  #
  # VALIDATE AND TEST before adding to connections!
  #
  # Currently added to
  # - SubmissionType
  class TotalCountPageInfo < GraphQL::Types::Relay::PageInfo
    # Provides the total count of items in a connection, regardless of pagination limits
    field :total_count,
          Integer,
          null: true,
          description: "Total number of items in the connection, ignoring pagination."

    # Calculate the total count efficiently while preserving query intent
    def total_count
      # Memoize to avoid multiple database calls for the same PageInfo object
      @total_count ||= calculate_total_count
    end

    private

    def calculate_total_count
      items = object.items
      return nil if items.nil?

      begin
        if items.respond_to?(:unscope)
          # Remove only pagination scopes, preserve all business logic
          # This keeps WHERE, GROUP BY, HAVING, JOIN, DISTINCT, etc.
          items.unscope(:limit, :offset, :order).count
        elsif items.respond_to?(:count)
          # For regular collections (arrays, etc.)
          items.count
        else
          # Fallback for other enumerables
          items.size
        end
      rescue => e
        # Log error in production but don't break the query
        log_count_error(e)
        nil
      end
    end

    def log_count_error(error)
      Rails.logger.warn(
        "GraphQL PageInfo total_count calculation failed: #{error.message}"
      )
    end
  end
end

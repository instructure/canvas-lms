# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Types
  class StreamSummaryItemType < ApplicationObjectType
    description "An activity stream summary item"
    field :count, Integer, null: true
    field :notification_category, String, null: true
    field :type, String, null: true
    field :unread_count, Integer, null: true
  end

  class ActivityStreamType < ApplicationObjectType
    include Api::V1::StreamItem
    description "An activity stream"

    VALID_CONTEXTS = %w[Course User Group].freeze

    def initialize(object, context)
      super
      @context_type = context[:context_type]
    end

    field :summary, [StreamSummaryItemType], null: true, description: "Returns a summary of the activity stream items for the current context"
    def summary
      @current_user = context[:current_user]
      opts = resolve_context
      # TODO: address this in LX-1855 to remove bulk load activity stream items
      items = calculate_stream_summary(opts)
      items.map do |item|
        {
          type: item[:type],
          count: item[:count],
          unread_count: item[:unread_count],
          notification_category: item[:notification_category]
        }
      end
    end

    private

    def resolve_context
      unless VALID_CONTEXTS.include?(@context_type)
        raise GraphQL::ExecutionError, I18n.t("Invalid context type")
      end

      case @context_type
      when "User"
        only_active_courses = context[:only_active_courses] || false
        { only_active_courses: }

      # Course or Group
      else
        { contexts: object }
      end
    end
  end
end

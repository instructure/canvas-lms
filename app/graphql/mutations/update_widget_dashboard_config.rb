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

class Mutations::UpdateWidgetDashboardConfig < Mutations::BaseMutation
  argument :filters, GraphQL::Types::JSON, required: false
  argument :widget_id, String, required: true

  field :filters, GraphQL::Types::JSON, null: true
  field :widget_id, String, null: false

  def resolve(input:) # rubocop:disable GraphQL/UnusedArgument
    widget_id = input[:widget_id]
    filters = input[:filters]

    validate_filters!(widget_id, filters) if filters

    config = current_user.get_preference(:widget_dashboard_config) || {}

    if filters
      config["filters"] ||= {}
      config["filters"][widget_id] = filters.is_a?(ActionController::Parameters) ? filters.to_unsafe_h : filters
    end

    current_user.set_preference(:widget_dashboard_config, config)

    { widget_id:, filters: }
  end

  ANNOUNCEMENTS_WIDGET_ID = "announcements-widget"
  TODO_LIST_WIDGET_ID = "todo-list-widget"
  COURSE_WORK_WIDGET_IDS = %w[
    course-work-widget
    course-work-combined-widget
    course-work-summary-widget
  ].freeze

  VALID_ANNOUNCEMENT_FILTERS = %w[unread read all].freeze
  VALID_TODO_FILTERS = %w[incomplete_items complete_items all].freeze
  VALID_DATE_FILTERS = %w[not_submitted missing submitted].freeze

  private

  def validate_filters!(widget_id, filters)
    # Accept Hash or ActionController::Parameters (which GraphQL JSON type may produce)
    unless filters.is_a?(Hash) || filters.is_a?(ActionController::Parameters)
      raise GraphQL::ExecutionError, "filters must be an object"
    end

    filters.each_key do |key|
      unless key.is_a?(String) && !key.empty?
        raise GraphQL::ExecutionError, "filter keys must be non-empty strings"
      end
    end

    validate_filter_structure!(widget_id, filters)
  end

  def validate_filter_structure!(widget_id, filters)
    if widget_id == ANNOUNCEMENTS_WIDGET_ID
      validate_announcements_filters!(filters)
    elsif widget_id == TODO_LIST_WIDGET_ID
      validate_todo_list_filters!(filters)
    elsif COURSE_WORK_WIDGET_IDS.include?(widget_id)
      validate_course_work_filters!(filters)
    else
      validate_generic_filters!(filters)
    end
  end

  def validate_announcements_filters!(filters)
    if filters.key?("filter")
      filter_value = filters["filter"]
      unless filter_value.is_a?(String) && VALID_ANNOUNCEMENT_FILTERS.include?(filter_value)
        raise GraphQL::ExecutionError, "filter must be one of: #{VALID_ANNOUNCEMENT_FILTERS.join(", ")}"
      end
    end

    invalid_keys = filters.keys - ["filter"]
    unless invalid_keys.empty?
      raise GraphQL::ExecutionError, "invalid filter keys for announcements widget: #{invalid_keys.join(", ")}"
    end
  end

  def validate_todo_list_filters!(filters)
    if filters.key?("filter")
      filter_value = filters["filter"]
      unless filter_value.is_a?(String) && VALID_TODO_FILTERS.include?(filter_value)
        raise GraphQL::ExecutionError, "filter must be one of: #{VALID_TODO_FILTERS.join(", ")}"
      end
    end

    invalid_keys = filters.keys - ["filter"]
    unless invalid_keys.empty?
      raise GraphQL::ExecutionError, "invalid filter keys for todo list widget: #{invalid_keys.join(", ")}"
    end
  end

  def validate_course_work_filters!(filters)
    if filters.key?("selectedCourse")
      course_value = filters["selectedCourse"]
      unless course_value.is_a?(String) && (course_value == "all" || course_value.match?(/^course_\d+$/))
        raise GraphQL::ExecutionError, "selectedCourse must be 'all' or 'course_{id}'"
      end
    end

    if filters.key?("selectedDateFilter")
      date_filter = filters["selectedDateFilter"]
      unless date_filter.is_a?(String) && VALID_DATE_FILTERS.include?(date_filter)
        raise GraphQL::ExecutionError, "selectedDateFilter must be one of: #{VALID_DATE_FILTERS.join(", ")}"
      end
    end

    invalid_keys = filters.keys - ["selectedCourse", "selectedDateFilter"]
    unless invalid_keys.empty?
      raise GraphQL::ExecutionError, "invalid filter keys for course work widget: #{invalid_keys.join(", ")}"
    end
  end

  def validate_generic_filters!(filters)
    filters.each_value do |value|
      validate_filter_value!(value)
    end
  end

  def validate_filter_value!(value)
    return if value.nil?

    case value
    when String, Numeric, TrueClass, FalseClass
      true
    when Hash
      value.each_value { |v| validate_filter_value!(v) }
    when Array
      value.each { |v| validate_filter_value!(v) }
    else
      raise GraphQL::ExecutionError, "filter values must be JSON-compatible types"
    end
  end
end

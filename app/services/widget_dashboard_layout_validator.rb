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

# Validates widget dashboard layout configuration stored in user preferences.
#
# @example Valid configuration
#   {
#     "columns" => 2,
#     "widgets" => [
#       {
#         "id" => "course-work-widget-uuid",
#         "type" => "course_work",
#         "position" => { "col" => 1, "row" => 1, "relative" => 1 },
#         "title" => "Course Work"
#       }
#     ]
#   }
#
# Schema Definition:
#
# {
#   columns: Integer (required, min: 1)
#     Number of columns in the dashboard grid
#
#   widgets: Array<Widget> (required)
#     Array of widget configurations
#
#   Widget {
#     id: String (required, non-empty)
#       Unique identifier for the widget instance
#
#     type: String (required, non-empty)
#       Widget type identifier (e.g., "course_work", "announcements")
#       Valid types: course_work_summary, course_work, course_work_combined,
#                    course_grades, announcements, people
#
#     position: Position (required)
#       Widget placement in the grid
#
#     title: String (required, non-empty)
#       Display title for the widget
#   }
#
#   Position {
#     col: Integer (required, min: 1, max: columns)
#       Column index where widget is placed
#
#     row: Integer (required, min: 1)
#       Row index where widget is placed
#
#     relative: Integer (required, min: 1)
#       Relative ordering for widget rendering
#   }
# }
#
# Validation Rules:
# - All required fields must be present and non-empty
# - All numeric fields must be positive integers
# - Widget type must be one of the valid types
# - Widget positions (col, row) must be unique across all widgets
# - Widget column index must not exceed configured columns count
class WidgetDashboardLayoutValidator
  # Valid widget types - keep in sync with WIDGET_TYPES in
  # ui/features/widget_dashboard/react/constants.ts
  VALID_WIDGET_TYPES = %w[
    course_work_summary
    course_work
    course_work_combined
    course_grades
    announcements
    people
    todo_list
    progress_overview
    recent_grades
    inbox
  ].freeze

  attr_reader :errors

  def initialize(layout)
    @layout = layout
    @errors = []
  end

  def valid?
    return false unless layout_structure_valid?
    return false unless columns_valid?
    return false unless widgets_valid?
    return false unless widget_positions_valid?
    return false unless no_duplicate_positions?

    @errors.empty?
  end

  private

  def layout_structure_valid?
    unless @layout.is_a?(Hash)
      @errors << I18n.t("Layout configuration must be an object")
      return false
    end

    unless @layout.key?("columns")
      @errors << I18n.t("Layout configuration must include 'columns' field")
      return false
    end

    unless @layout.key?("widgets")
      @errors << I18n.t("Layout configuration must include 'widgets' field")
      return false
    end

    true
  end

  def columns_valid?
    columns = @layout["columns"]

    unless columns.is_a?(Integer)
      @errors << I18n.t("'columns' must be an integer")
      return false
    end

    unless columns.positive?
      @errors << I18n.t("'columns' must be a positive integer")
      return false
    end

    true
  end

  def widgets_valid?
    widgets = @layout["widgets"]

    unless widgets.is_a?(Array)
      @errors << I18n.t("'widgets' must be an array")
      return false
    end

    widgets.each_with_index do |widget, index|
      validate_widget(widget, index)
    end

    @errors.empty?
  end

  def validate_widget(widget, index)
    unless widget.is_a?(Hash)
      @errors << I18n.t("Widget at index %{index} must be an object", index:)
      return
    end

    validate_required_field(widget, "id", index)
    validate_required_field(widget, "type", index)
    validate_required_field(widget, "position", index)
    validate_required_field(widget, "title", index)

    validate_widget_type(widget["type"], index) if widget["type"]

    return unless widget["position"]

    validate_position(widget["position"], index)
  end

  def validate_widget_type(type, index)
    return if VALID_WIDGET_TYPES.include?(type)

    @errors << I18n.t(
      "Widget at index %{index} has invalid type '%{type}'.",
      index:,
      type:
    )
  end

  def validate_required_field(widget, field, index)
    return if widget.key?(field) && !widget[field].nil? && widget[field] != ""

    @errors << I18n.t("Widget at index %{index} must have '%{field}' field", index:, field:)
  end

  def validate_position(position, widget_index)
    unless position.is_a?(Hash)
      @errors << I18n.t("Position for widget at index %{index} must be an object", index: widget_index)
      return
    end

    validate_position_field(position, "col", widget_index)
    validate_position_field(position, "row", widget_index)
    validate_position_field(position, "relative", widget_index)
  end

  def validate_position_field(position, field, widget_index)
    unless position.key?(field)
      @errors << I18n.t("Position for widget at index %{index} must have '%{field}' field", index: widget_index, field:)
      return
    end

    value = position[field]

    unless value.is_a?(Integer)
      @errors << I18n.t("Position '%{field}' for widget at index %{index} must be an integer", field:, index: widget_index)
      return
    end

    unless value.positive?
      @errors << I18n.t("Position '%{field}' for widget at index %{index} must be a positive integer", field:, index: widget_index)
    end
  end

  def widget_positions_valid?
    return true unless @layout["widgets"].is_a?(Array)

    columns = @layout["columns"]
    @layout["widgets"].each_with_index do |widget, index|
      next unless widget.is_a?(Hash) && widget["position"].is_a?(Hash)

      col = widget.dig("position", "col")
      next unless col.is_a?(Integer)

      if col > columns
        @errors << I18n.t("Widget at index %{index} has column %{col} which exceeds configured columns %{columns}", index:, col:, columns:)
      end
    end

    @errors.empty?
  end

  def no_duplicate_positions?
    return true unless @layout["widgets"].is_a?(Array)

    positions = {}
    @layout["widgets"].each_with_index do |widget, index|
      next unless widget.is_a?(Hash) && widget["position"].is_a?(Hash)

      col = widget.dig("position", "col")
      row = widget.dig("position", "row")

      next unless col.is_a?(Integer) && row.is_a?(Integer)

      position_key = "#{col},#{row}"
      if positions.key?(position_key)
        @errors << I18n.t("Multiple widgets at position (col: %{col}, row: %{row})", col:, row:)
      else
        positions[position_key] = index
      end
    end

    @errors.empty?
  end
end

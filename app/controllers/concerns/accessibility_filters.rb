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

module AccessibilityFilters
  extend ActiveSupport::Concern

  # Apply filtering logic.
  # Filters include rule types, resource types, workflow states, and date ranges.
  #
  # Invalid or missing filters are ignored. All conditions are combined with AND logic.
  #
  # @param relation [ActiveRecord::Relation] the base query
  # @param filters [Hash] the filter parameters
  # @return [ActiveRecord::Relation] the filtered query
  def apply_accessibility_filters(relation, filters = {}, search = nil)
    filters = filters.presence || {}

    return relation if filters.empty? && search.blank?

    rule_types = filters[:ruleTypes]
    resource_types = filters[:artifactTypes]
    workflow_states = filters[:workflowStates]
    from_date = parse_date_safely(filters[:fromDate])
    to_date = parse_date_safely(filters[:toDate])

    relation = apply_rule_type_filter(relation, rule_types) if rule_types.present?
    relation = apply_resource_type_filter(relation, resource_types) if resource_types.present?
    relation = apply_workflow_state_filter(relation, workflow_states) if workflow_states.present?
    relation = apply_search_term_filter(relation, search) if search.present?
    relation = apply_date_range_filter(relation, from_date, to_date) if from_date.present? || to_date.present?

    relation
  end

  # Apply search term filtering
  # @param relation [ActiveRecord::Relation] the base query
  # @param search_term [String] the term to search for
  # @return [ActiveRecord::Relation] the filtered query
  def apply_search_term_filter(relation, search_term)
    return relation if search_term.blank?

    sanitized_term = ActiveRecord::Base.sanitize_sql_like(search_term.strip)
    term = "%#{sanitized_term.downcase}%"

    relation.where("accessibility_resource_scans.resource_name ILIKE :term", term:)
  end

  private

  # Parse date string safely
  # @param date_string [String] the date string to parse
  # @return [Time, nil] parsed time or nil
  def parse_date_safely(date_string)
    return nil if date_string.blank?

    Time.zone.parse(date_string)
  rescue
    nil
  end

  # Apply rule type filtering by joining with accessibility_issues
  # @param relation [ActiveRecord::Relation] the base query
  # @param rule_types [Array<String>] rule types to filter by
  # @return [ActiveRecord::Relation] the filtered query
  def apply_rule_type_filter(relation, rule_types)
    return relation if rule_types.blank?

    relation.joins(:accessibility_issues)
            .where(accessibility_issues: { rule_type: rule_types })
            .distinct
  end

  # Apply resource type filtering based on resource types
  # @param relation [ActiveRecord::Relation] the base query
  # @param resource_types [Array<String>] resource types to filter by
  # @return [ActiveRecord::Relation] the filtered query
  def apply_resource_type_filter(relation, resource_types)
    return relation if resource_types.blank?

    resource_types = Array(resource_types).map(&:to_s)
    valid_resource_types = %w[wiki_page assignment discussion_topic announcement syllabus]
    valid_filters = resource_types & valid_resource_types

    return relation.none if valid_filters.empty?

    conditions = []
    conditions << "accessibility_resource_scans.wiki_page_id IS NOT NULL" if valid_filters.include?("wiki_page")
    conditions << "accessibility_resource_scans.assignment_id IS NOT NULL" if valid_filters.include?("assignment")
    conditions << "accessibility_resource_scans.discussion_topic_id IS NOT NULL" if valid_filters.include?("discussion_topic")
    conditions << "accessibility_resource_scans.announcement_id IS NOT NULL" if valid_filters.include?("announcement")
    conditions << "accessibility_resource_scans.is_syllabus = true" if valid_filters.include?("syllabus")

    return relation if conditions.empty?

    relation.where(conditions.join(" OR "))
  end

  # Apply workflow state filtering
  # @param relation [ActiveRecord::Relation] the base query
  # @param workflow_states [Array<String>] workflow states to filter by
  # @return [ActiveRecord::Relation] the filtered query
  def apply_workflow_state_filter(relation, workflow_states)
    return relation if workflow_states.blank?

    relation.where(resource_workflow_state: workflow_states)
  end

  # Apply date range filtering
  # @param relation [ActiveRecord::Relation] the base query
  # @param from_date [Time, nil] start date for filtering
  # @param to_date [Time, nil] end date for filtering
  # @return [ActiveRecord::Relation] the filtered query
  def apply_date_range_filter(relation, from_date, to_date)
    relation = relation.where(resource_updated_at: from_date.beginning_of_day..) if from_date.present?
    relation = relation.where(resource_updated_at: ..to_date.end_of_day) if to_date.present?
    relation
  end

  # Given a search term, return an array of rule types whose display names
  # include the term (case insensitive).
  #
  # @param term [String] the search term
  # @return [Array<String>] the matching rule types
  def rule_types_from_label_search(term)
    downcased_term = term.downcase.strip

    Accessibility::Rule.registry.select do |_type, rule|
      rule.display_name.downcase.include?(downcased_term)
    end.keys
  end
end

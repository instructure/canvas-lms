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

require_relative "../../common"

class IssuesTableComponent
  include SeleniumDependencies

  def table_selector
    "[data-testid='accessibility-issues-table']"
  end

  def table_row_selector
    "[data-testid^='issue-row-']"
  end

  def no_issues_message_selector
    "[data-testid='no-issues-row']"
  end

  def loading_row_selector
    "[data-testid='loading-row']"
  end

  def pagination_selector
    "[data-testid='accessibility-issues-table-pagination']"
  end

  def resource_name_link_selector
    "[data-pendo='navigate-to-resource-url']"
  end

  def table
    f(table_selector)
  end

  def table_exists?
    element_exists?(table_selector)
  end

  def table_rows
    return [] unless table_exists?
    return [] unless element_exists?(table_row_selector)

    ff(table_row_selector)
  end

  def no_issues_message_exists?
    element_exists?(no_issues_message_selector)
  end

  def no_issues_message
    f(no_issues_message_selector).text
  end

  def loading_row_exists?
    element_exists?(loading_row_selector)
  end

  def pagination
    f(pagination_selector)
  end

  def pagination_exists?
    element_exists?(pagination_selector)
  end

  def resource_name_links
    return [] if table_rows.empty?

    ff(resource_name_link_selector)
  end

  def visible?
    table_exists?
  end

  def wait_for_table_to_load
    wait_for_ajaximations
    keep_trying_until { table_exists? && !loading_row_exists? }
  end

  def row_count
    table_rows.length
  end

  def has_no_issues_rows?
    table_rows.any? && all_issue_counts.all?(&:zero?)
  end

  def all_resource_names
    resource_name_links.map(&:text)
  end

  def all_issue_counts
    table_rows.map { |row| get_row_data(row)[:issues].to_i }
  end

  def first_row
    IssuesTableRow.new(table_rows.first) if table_rows.any?
  end

  def find_row_by_resource_name(name)
    row = table_rows.find do |row|
      cells = row.find_elements(:css, "td")
      cells.first&.text&.include?(name)
    end
    IssuesTableRow.new(row) if row
  end

  def rows
    table_rows.map { |row_element| IssuesTableRow.new(row_element) }
  end

  def go_to_next
    go_to_page(current_page + 1)
  end

  def go_to_previous
    go_to_page(current_page - 1)
  end

  def current_page
    pagination.find_element(:css, "[aria-current='page']").text.to_i
  end

  private

  def go_to_page(page_number)
    button = find_pagination_button(page_number)
    button&.click
    wait_for_ajaximations
    wait_for_table_to_load
  end

  def find_pagination_button(page_number)
    pagination.find_elements(:css, "button").find { |btn| btn.text.strip == page_number.to_s }
  end

  def get_row_data(row)
    cells = row.find_elements(:css, "td")
    {
      resource_name: cells[0]&.text,
      issues: cells[1]&.text,
      content_type: cells[2]&.text,
      status: cells[3]&.text,
      last_edited: cells[4]&.text
    }
  end

  class IssuesTableRow
    include SeleniumDependencies

    def initialize(row_element)
      @row = row_element
    end

    def click_fix_button
      fix_button = f("[data-testid='issue-remediation-button']", @row)
      fix_button.click
      wait_for_ajaximations
    end

    def resource_name
      f("td", @row).text
    end

    def resource_type
      cells = ff("td", @row)
      cells[2]&.text if cells.length > 2
    end
  end
end

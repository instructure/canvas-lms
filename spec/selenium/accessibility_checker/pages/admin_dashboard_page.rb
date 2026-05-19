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

module AdminDashboardPage
  NO_ISSUES_TEXT = "No issues"
  ALL_TERMS_OPTION = "All terms"

  COLUMNS = {
    course_name: "Course",
    issues: "Issues",
    resolved: "Resolved",
    term: "Term",
    status: "Status"
  }.freeze

  COLUMN_CELL_TESTIDS = %w[
    status-cell
    course-name-cell
    issues-cell
    resolved-issues-cell
    term-cell
    teachers-cell
    subaccount-cell
    student-count-cell
  ].freeze

  def wait_for_dashboard_to_load
    wait_for_ajaximations
    keep_trying_until(15) do
      element_exists?("[data-testid='course-name-cell']")
    end
  end

  def column_label(key)
    COLUMNS[key]
  end

  def all_terms_option_label
    ALL_TERMS_OPTION
  end

  def all_table_columns_present?
    COLUMN_CELL_TESTIDS.all? { |testid| element_exists?("[data-testid='#{testid}']") }
  end

  def course_row_present?(course_name)
    !fj("[data-testid='course-name-cell']:contains('#{course_name}')").nil?
  rescue
    false
  end

  def course_row_matches?(course_name, active_issue_count:, resolved_issue_count:)
    course_row_present?(course_name) &&
      !fj("[data-testid='issues-cell']:contains('#{active_issue_count}')").nil? &&
      !fj("[data-testid='resolved-issues-cell']:contains('#{resolved_issue_count}')").nil?
  rescue
    false
  end

  def course_name_cells
    ff("[data-testid='course-name-cell']")
  end

  def click_course_name(course_name)
    fj("[data-testid='course-name-cell']:contains('#{course_name}') a").click
    wait_for_ajaximations
  end

  def course_names_in_order
    course_name_cells.map(&:text)
  end

  def course_index(names, partial_name)
    names.index { |n| n.include?(partial_name) }
  end

  def issues_cell_shows?(count)
    !fj("[data-testid='issues-cell']:contains('#{count}')").nil?
  rescue
    false
  end

  def resolved_issues_cell_shows?(count)
    !fj("[data-testid='resolved-issues-cell']:contains('#{count}')").nil?
  rescue
    false
  end

  def issues_cell_shows_no_issues?
    !fj("[data-testid='issues-cell']:contains('#{NO_ISSUES_TEXT}')").nil?
  rescue
    false
  end

  def no_courses_found?
    !fj("*:contains('No courses found')").nil?
  rescue
    false
  end

  def bar_chart
    f("[data-testid='bar-chart']")
  end

  def bar_chart_description_text
    describedby_id = bar_chart.attribute("aria-describedby")
    f("[id='#{describedby_id}']").text
  end

  def type_in_search(query)
    f("input[type='search']").send_keys(query)
    wait_for_ajaximations
  end

  def search_courses(query)
    type_in_search(query)
    wait_for_courses_to_reload
  end

  def clear_course_search
    f("[data-testid='clear-search-button']").click
    wait_for_courses_to_reload
  end

  def open_term_filter
    f("input[placeholder='Filter by term']").click
    wait_for_ajaximations
  end

  def select_term(term_name)
    open_term_filter
    fj("[role='option']:contains('#{term_name}')").click
    wait_for_ajaximations
  end

  def sort_ascending(label)
    sort_column(label, "ascending")
  end

  def sort_descending(label)
    sort_column(label, "descending")
  end

  def pagination
    f("[data-testid='courses-pagination']")
  end

  def click_next_page
    current_page = f("[data-testid='courses-pagination'] [aria-current='page']").text.strip.to_i
    fj("[data-testid='courses-pagination'] button:contains('#{current_page + 1}')").click
    wait_for_ajaximations
  end

  def click_previous_page
    current_page = f("[data-testid='courses-pagination'] [aria-current='page']").text.strip.to_i
    fj("[data-testid='courses-pagination'] button:contains('#{current_page - 1}')").click
    wait_for_ajaximations
  end

  private

  def wait_for_courses_to_reload
    spinner_appears_within?(5)
    keep_trying_until(10) { !loading_courses_spinner_visible? }
    wait_for_ajaximations
  end

  def spinner_appears_within?(seconds)
    keep_trying_until(seconds) { loading_courses_spinner_visible? }
    true
  rescue
    false
  end

  def loading_courses_spinner_visible?
    !fj("*:contains('Loading courses')").nil?
  rescue
    false
  end

  def click_column_sort(label)
    fj("th button:contains('#{label}')").click
    wait_for_ajaximations
  end

  def sort_column(label, direction)
    th = fj("th button:contains('#{label}')").find_element(:xpath, "ancestor::th")
    return if th.attribute("aria-sort") == direction

    click_column_sort(label)
    th = fj("th button:contains('#{label}')").find_element(:xpath, "ancestor::th")
    click_column_sort(label) unless th.attribute("aria-sort") == direction
  end
end

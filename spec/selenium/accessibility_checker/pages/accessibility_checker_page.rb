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
require_relative "../components/issues_table_component"
require_relative "../components/issues_summary_component"
require_relative "../components/filters_panel_component"
require_relative "../components/search_component"
require_relative "../components/remediation_wizard/remediation_wizard_component"

module AccessibilityCheckerPage
  def accessibility_checker_app_selector
    "[data-testid='accessibility-checker-app']"
  end

  def scan_course_button_selector
    "button"
  end

  def page_title_selector
    "h1"
  end

  def accessibility_checker_app
    f(accessibility_checker_app_selector)
  end

  def accessibility_checker_app_exists?
    element_exists?(accessibility_checker_app_selector)
  end

  def scan_course_button
    fj("button:contains('Scan Course')")
  end

  def page_title
    f(page_title_selector)
  end

  def page_title_exists?
    element_exists?(page_title_selector)
  end

  def no_scan_message_visible?
    !fj("#content span:contains('You haven\\'t scanned your course yet')").nil?
  rescue
    false
  end

  def visit_accessibility_checker(course)
    get "/courses/#{course.id}/accessibility"
    wait_for_ajaximations
  end

  def wait_for_accessibility_checker_to_load
    wait_for_ajaximations
    keep_trying_until(15) do
      page_title_exists?
    end
  end

  def click_scan_course_button
    scan_course_button.click
    wait_for_ajaximations
    run_jobs
    wait_for_ajaximations
  end

  def scanning_in_progress?
    !fj("body:contains('Hang tight!')").nil?
  rescue
    false
  end

  def wait_for_scan_to_complete
    wait_for_ajaximations
    return if accessibility_checker_app_exists?

    wait_for_scan_to_start
    wait_for_scanning_to_finish
    wait_for_app_to_load
  end

  def issues_table
    @issues_table ||= IssuesTableComponent.new
  end

  def issues_summary
    @issues_summary ||= IssuesSummaryComponent.new
  end

  def filters_panel
    @filters_panel ||= FiltersPanelComponent.new
  end

  def search_component
    @search_component ||= SearchComponent.new
  end

  def remediation_wizard
    @remediation_wizard ||= RemediationWizardComponent.new
  end

  def enable_accessibility_checker(course)
    course.account.enable_feature!(:a11y_checker)
    course.enable_feature!(:a11y_checker_eap)
  end

  def has_issues?
    return false unless issues_summary.visible?

    issues_summary.total_count > 0
  end

  def filter_panel_visible?
    filters_panel.visible?
  end

  def open_filter_panel
    filters_panel.open unless filter_panel_visible?
  end

  def search_for_resource(query)
    search_component.search(query)
    wait_for_search_to_complete
  end

  def clear_search
    search_component.clear
    wait_for_search_to_complete
  end

  def sort_by_column(column_name)
    table = f("[data-testid='accessibility-issues-table']")
    header_button = fj("thead button:contains('#{column_name}')", table)
    header_button.click
    wait_for_ajaximations
    issues_table.wait_for_table_to_load
  end

  def sort_by_resource_name
    sort_by_column("Resource")
  end

  def sort_by_issue_count
    sort_by_column("Issues")
  end

  private

  def wait_for_search_to_complete
    wait_for_ajaximations

    begin
      keep_trying_until(2) do
        element_exists?("[data-testid='loading-row']")
      end
    rescue Selenium::WebDriver::Error::TimeoutError
      raise unless element_exists?("[data-testid='accessibility-issues-table']")
    end

    issues_table.wait_for_table_to_load
  end

  def wait_for_scan_to_start
    keep_trying_until(10) do
      scanning_in_progress? || accessibility_checker_app_exists?
    end
  rescue Selenium::WebDriver::Error::TimeoutError
    raise unless accessibility_checker_app_exists?
  end

  def wait_for_scanning_to_finish
    return unless scanning_in_progress?

    keep_trying_until(90) do
      !scanning_in_progress?
    end
  end

  def wait_for_app_to_load
    wait_for_ajaximations
    keep_trying_until(10) do
      accessibility_checker_app_exists?
    end
  end
end

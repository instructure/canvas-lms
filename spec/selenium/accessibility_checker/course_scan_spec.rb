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

require_relative "../common"
require_relative "pages/accessibility_checker_page"
require_relative "support/batch_data_factory"

describe "Accessibility Checker Course Scan", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include AccessibilityCheckerPage
  include AccessibilityChecker::BatchDataFactory

  before(:once) do
    course_with_teacher(active_all: true)
    enable_accessibility_checker(@course)
  end

  before do
    user_session(@teacher)
  end

  context "Empty state (no scan run yet)" do
    it "displays the page title" do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load

      expect(page_title).to be_displayed
      expect(page_title.text).to include("Accessibility Checker")
    end

    it "displays no scan message" do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load

      expect(no_scan_message_visible?).to be true
    end

    it "displays scan course button" do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load

      expect(scan_course_button).to be_displayed
      expect(scan_course_button.text).to eq("Scan Course")
    end
  end

  context "Initiating scan" do
    before(:once) do
      create_page_with(@course, :missing_alt_text)
    end

    it "displays issues when scan course button is clicked" do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete

      expect(has_issues?).to be true
    end
  end

  context "Course with accessibility issues" do
    before(:once) do
      @page1 = create_page_with(@course, :missing_alt_text)
      @page2 = create_page_with(@course, :missing_alt_text)
      @page3 = create_page_with(@course, :table_no_headers)
      @expected_total_issues = expected_issue_count_for(@page1) + expected_issue_count_for(@page2) + expected_issue_count_for(@page3)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
    end

    it "displays issues summary after data loads" do
      expect(issues_summary.visible?).to be true
    end

    it "shows correct total issue count" do
      total = issues_summary.total_count

      expect(total).to eq(@expected_total_issues)
    end

    it "displays issues table after data loads" do
      expect(issues_table.visible?).to be true
    end

    it "shows resources in the table" do
      expect(issues_table.row_count).to eq(3)
    end
  end

  context "Course without accessibility issues" do
    before(:once) do
      create_page_with(@course, :valid_alt_text)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
    end

    it "displays zero issues in summary" do
      expect(issues_summary.total_count).to eq(0)
    end

    it "shows resources with no issues in table" do
      expect(issues_table.visible?).to be true
      expect(issues_table.has_no_issues_rows?).to be true
    end
  end

  context "Search functionality" do
    before(:once) do
      @course.wiki_pages.destroy_all

      @searchable_page = create_page_with(@course, :missing_alt_text, title: "Searchable Item")
      @other_page = create_page_with(@course, :missing_alt_text)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
    end

    it "displays search bar" do
      expect(search_component.visible?).to be true
    end

    it "displays no results when search query does not match any resources" do
      search_for_resource("Nonexistent")

      expect(issues_table.row_count).to eq(0)
      expect(issues_table.no_issues_message_exists?).to be true
      expect(issues_table.no_issues_message).to include("No accessibility issues found")
      expect(issues_table.pagination_exists?).to be false
    end

    it "filters table by search query" do
      search_for_resource("Searchable")

      resource_names = issues_table.all_resource_names
      expect(resource_names).to include(@searchable_page.title)
      expect(resource_names).not_to include(@other_page.title)
    end

    it "shows all results when search is cleared" do
      search_for_resource("Searchable")
      clear_search
      wait_for_ajaximations

      expect(issues_table.row_count).to eq(2)
    end
  end

  context "Filter panel" do
    before(:once) do
      create_page_with(@course, :missing_alt_text)
      create_assignment_with(@course, :missing_alt_text)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
    end

    it "filters by resource type" do
      filter_panel = filters_panel
      open_filter_panel

      filter_panel.toggle_resource_type(:pages)
      filter_panel.apply_filters
      wait_for_ajaximations
      resource_types = issues_table.rows.map(&:resource_type)
      expect(resource_types.uniq.length).to eq(1)
      expect(resource_types).to all(eq("Page"))
    end
  end

  context "Table sorting" do
    before(:once) do
      @course.wiki_pages.destroy_all

      @first_page = create_page_with(@course, :missing_alt_text, title: "Alpha Page")
      create_page_with(@course, :multiple_issues, title: "Beta Page")
      create_page_with(@course, :table_no_headers, title: "Gamma Page")
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
    end

    it "sorts table by resource name" do
      sort_by_resource_name

      first_name = issues_table.first_row.resource_name
      expect(first_name).to eq(@first_page.title)
    end

    it "sorts table by issue count descending" do
      sort_by_issue_count
      sort_by_issue_count

      counts = issues_table.all_issue_counts
      expect(counts.first).to be >= counts.last
    end
  end

  context "Opening remediation wizard" do
    before(:once) do
      @test_page = create_page_with(@course, :missing_alt_text)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
    end

    it "opens wizard when fix button is clicked" do
      issues_table.first_row.click_fix_button

      expect(remediation_wizard.visible?).to be true
    end

    it "displays wizard header with resource name" do
      issues_table.first_row.click_fix_button
      wizard = remediation_wizard

      expect(wizard.header.visible?).to be true
      expect(wizard.header.resource_name).to include(@test_page.title)
    end

    it "displays problem area in wizard" do
      issues_table.first_row.click_fix_button
      wizard = remediation_wizard

      expect(wizard.problem_area.visible?).to be true
    end
  end

  context "Issues navigation" do
    before(:once) do
      @course.wiki_pages.destroy_all

      @multi_issue_page = create_page_with(@course, :multiple_issues)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
      issues_table.find_row_by_resource_name(@multi_issue_page.title).click_fix_button
      wait_for_ajaximations
      wizard = remediation_wizard
      wizard.wait_for_form_to_render
    end

    it "shows issue counter in header" do
      wizard = remediation_wizard

      expect(wizard.header.current_issue_number).to eq(1)
      expect(wizard.header.total_issues).to eq(expected_issue_count_for(@multi_issue_page))
    end

    it "shows next issue when skip button is clicked" do
      wizard = remediation_wizard
      first_issue = wizard.problem_area.issue_description

      wizard.skip_issue

      expect(wizard.header.current_issue_number).to eq(2)
      expect(wizard.header.total_issues).to eq(expected_issue_count_for(@multi_issue_page))
      expect(wizard.problem_area.issue_description).not_to eq(first_issue)
    end
  end

  context "Pagination" do
    before(:once) do
      @course.wiki_pages.destroy_all

      create_paginated_content(@course, count: 25)
    end

    before do
      visit_accessibility_checker(@course)
      wait_for_accessibility_checker_to_load
      click_scan_course_button
      wait_for_scan_to_complete
    end

    it "displays pagination controls" do
      expect(issues_table.pagination_exists?).to be true
    end

    it "shows current page number" do
      expect(issues_table.current_page).to eq(1)
    end

    it "navigates to next page" do
      issues_table.wait_for_table_to_load
      first_page_resources = issues_table.all_resource_names

      issues_table.go_to_next
      issues_table.wait_for_table_to_load

      expect(issues_table.current_page).to eq(2)
      second_page_resources = issues_table.all_resource_names
      expect(first_page_resources).not_to eq(second_page_resources)
    end

    it "navigates between multiple pages" do
      issues_table.wait_for_table_to_load
      issues_table.go_to_next
      expect(issues_table.current_page).to eq(2)

      issues_table.go_to_previous
      expect(issues_table.current_page).to eq(1)
    end
  end
end

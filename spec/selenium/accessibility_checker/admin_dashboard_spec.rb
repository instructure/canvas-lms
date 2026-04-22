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
require_relative "pages/admin_dashboard_page"
require_relative "pages/accessibility_checker_page"
require_relative "support/dashboard_data_factory"

describe "Accessibility Checker - Admin Dashboard", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include AdminDashboardPage
  include AccessibilityCheckerPage
  include AccessibilityChecker::DashboardDataFactory

  def visit_admin_dashboard
    get "/accounts/#{@account.id}/accessibility"
    wait_for_ajaximations
  end

  before(:once) do
    @account = Account.default
    Account.site_admin.enable_feature!(:a11y_checker_account_statistics)
    @account.enable_feature!(:a11y_checker)
    @admin = account_admin_user(account: @account)
  end

  before do
    user_session(@admin)
    visit_admin_dashboard
    wait_for_dashboard_to_load
  end

  context "Course table and bar chart" do
    let(:course_name) { dashboard_course_name_for(:spring_course) }
    let(:course_statistics) { statistic_fixture_for(:spring_course) }

    before(:once) do
      create_course_with_statistic(@account, :spring_course)
    end

    it "displays the courses table with correct columns and course data" do
      expect(all_table_columns_present?).to be true
      expect(course_row_matches?(course_name, **course_statistics)).to be true
    end

    it "shows the issue summary bar chart with correct open and resolved issue counts" do
      description = bar_chart_description_text

      expect(description).to include(course_statistics[:active_issue_count].to_s)
      expect(description).to include(course_statistics[:resolved_issue_count].to_s)
    end
  end

  context "Search functionality" do
    let(:searchable_course_name) { dashboard_course_name_for(:spring_course) }
    let(:other_course_name) { dashboard_course_name_for(:fall_course) }
    let(:search_query) { searchable_course_name.first(3) }
    let(:non_matching_search_term) { "xyznotfound" }

    before(:once) do
      create_dashboard_course(@account, :spring_course)
      create_dashboard_course(@account, :fall_course)
    end

    it "does not trigger search with fewer than 3 characters" do
      type_in_search(search_query.first(2))

      expect(course_row_present?(searchable_course_name)).to be true
      expect(course_row_present?(other_course_name)).to be true
    end

    it "searches courses by course name" do
      search_courses(search_query)

      expect(course_row_present?(searchable_course_name)).to be true
      expect(course_row_present?(other_course_name)).to be false
    end

    it "shows no results for a non-matching search term" do
      search_courses(non_matching_search_term)

      expect(no_courses_found?).to be true
    end

    it "shows all courses when search is cleared" do
      search_courses(search_query)
      expect(course_row_present?(other_course_name)).to be false

      clear_course_search
      expect(course_row_present?(searchable_course_name)).to be true
      expect(course_row_present?(other_course_name)).to be true
    end
  end

  context "Term filter" do
    before(:once) do
      @spring_term = create_enrollment_term(@account, :spring_term)
      @fall_term = create_enrollment_term(@account, :fall_term)

      create_dashboard_course(@account, :spring_course, term_id: @spring_term.id)
      create_dashboard_course(@account, :other_spring_course, term_id: @spring_term.id)
      create_dashboard_course(@account, :fall_course, term_id: @fall_term.id)
    end

    it "filters courses by a term with multiple courses" do
      select_term(@spring_term.name)

      expect(course_row_present?(dashboard_course_name_for(:spring_course))).to be true
      expect(course_row_present?(dashboard_course_name_for(:other_spring_course))).to be true
      expect(course_row_present?(dashboard_course_name_for(:fall_course))).to be false
    end

    it "filters courses by a term with a single course" do
      select_term(@fall_term.name)

      expect(course_row_present?(dashboard_course_name_for(:fall_course))).to be true
      expect(course_row_present?(dashboard_course_name_for(:spring_course))).to be false
    end

    it "shows all term courses when All terms is selected" do
      select_term(all_terms_option_label)

      expect(course_row_present?(dashboard_course_name_for(:spring_course))).to be true
      expect(course_row_present?(dashboard_course_name_for(:other_spring_course))).to be true
      expect(course_row_present?(dashboard_course_name_for(:fall_course))).to be true
    end
  end

  context "Sorting" do
    let(:first_course_identifier) { dashboard_course_name_for(:fall_course) }
    let(:last_course_identifier) { dashboard_course_name_for(:spring_course) }

    before(:once) do
      spring_term = create_enrollment_term(@account, :spring_term)
      fall_term = create_enrollment_term(@account, :fall_term)
      create_course_with_statistic(@account, :fall_course, term_id: fall_term.id)
      create_course_with_statistic(@account, :spring_course, term_id: spring_term.id)
    end

    it "sorts courses by course name ascending" do
      sort_ascending(column_label(:course_name))
      names = course_names_in_order
      expect(course_index(names, first_course_identifier)).to be < course_index(names, last_course_identifier)
    end

    it "sorts courses by issue count descending" do
      sort_descending(column_label(:issues))
      names = course_names_in_order
      expect(course_index(names, last_course_identifier)).to be < course_index(names, first_course_identifier)
    end

    it "sorts courses by resolved issue count ascending" do
      sort_ascending(column_label(:resolved))
      names = course_names_in_order
      expect(course_index(names, last_course_identifier)).to be < course_index(names, first_course_identifier)
    end

    it "sorts courses by term descending" do
      sort_descending(column_label(:term))
      names = course_names_in_order
      expect(course_index(names, last_course_identifier)).to be < course_index(names, first_course_identifier)
    end

    it "sorts courses by status descending" do
      sort_descending(column_label(:status))
      names = course_names_in_order
      expect(course_index(names, last_course_identifier)).to be < course_index(names, first_course_identifier)
    end
  end

  context "Course navigation" do
    let(:course_name) { dashboard_course_name_for(:fall_course) }

    before(:once) do
      create_dashboard_course(@account, :fall_course)
      enable_accessibility_checker(@course)
    end

    it "clicking a course name navigates to the course accessibility checker" do
      click_course_name(course_name)
      wait_for_accessibility_checker_to_load

      expect(scan_course_button.displayed?).to be true
    end
  end

  context "Issue count display" do
    let(:course_with_active_issues) { dashboard_course_name_for(:spring_course) }
    let(:course_with_no_issues) { dashboard_course_name_for(:other_spring_course) }
    let(:course_with_resolved_issues) { dashboard_course_name_for(:fall_course) }

    before(:once) do
      create_course_with_statistic(@account, :spring_course)
      create_course_with_statistic(@account, :other_spring_course)
      create_course_with_statistic(@account, :fall_course)
    end

    it "shows correct active issue count for a scanned course" do
      search_courses(course_with_active_issues)

      expect(issues_cell_shows?(statistic_fixture_for(:spring_course)[:active_issue_count])).to be true
    end

    it "shows zero issues for a course with no accessibility problems" do
      search_courses(course_with_no_issues)

      expect(issues_cell_shows_no_issues?).to be true
    end

    it "shows correct resolved issue count for a scanned course" do
      search_courses(course_with_resolved_issues)

      expect(resolved_issues_cell_shows?(statistic_fixture_for(:fall_course)[:resolved_issue_count])).to be true
    end
  end

  context "Pagination" do
    before(:once) do
      create_paginated_courses(@account)
    end

    it "shows pagination controls when there are multiple pages of courses" do
      expect(pagination.displayed?).to be true
    end

    it "navigates between pages showing different courses" do
      first_page_courses = course_names_in_order
      click_next_page
      second_page_courses = course_names_in_order

      expect(second_page_courses).not_to eq(first_page_courses)

      click_previous_page

      expect(course_names_in_order).to eq(first_page_courses)
      expect(course_names_in_order).not_to eq(second_page_courses)
    end
  end
end

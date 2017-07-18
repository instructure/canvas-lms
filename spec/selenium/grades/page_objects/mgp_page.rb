#
# Copyright (C) 2016 - present Instructure, Inc.
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

module GradingStandards
  class MultipleGradingPeriods
    include SeleniumDependencies

    # Main page components
    def grading_periods_tab
      f("#grading-periods-tab")
    end

    def add_set_of_grading_periods_button
      f('button[aria-label="Add Set of Grading Periods"]')
    end

    def term_dropdown
      f('select[aria-label="Enrollment Term"]')
    end

    def search_box
      f('.GradingPeriodSearchField input')
    end

    # Set components
    def set_name_input
      f('#set-name')
    end

    def term_input
      f('input[aria-label^="Start typing to search."]')
    end

    def create_set_button
      fj('button:contains("Create")')
    end

    def grading_period_set_title_css
      ".GradingPeriodSet__title"
    end

    def set_title
      f(grading_period_set_title_css)
    end

    def weighted_checkbox
      f('input[value^="weighted"]').find_element(:xpath, "..")
    end

    def show_total_checkbox
      f('input[value^="totals"]').find_element(:xpath, "..")
    end

    def show_total_checkbox_checked?
      f('input[value^="totals"]').attribute("checked")
    end

    def add_grading_period_link
      f('button[aria-label="Add Grading Period"]')
    end

    def delete_grading_period_set_button
      f('#grading-period-sets button[title^="Delete "]')
    end

    def edit_grading_period_set_button
      f('#grading-period-sets button[title^="Edit "]')
    end

    def edit_set_save_button
      f('button[aria-label="Save Grading Period Set"]')
    end

    def first_collapsed_set
      f('.GradingPeriodSet--collapsed')
    end

    def all_sets_css
      '.GradingPeriodSet__title'
    end

    # Period components
    def period_title_input
      f('#title')
    end

    def start_date_input
      f('input[data-row-key="start-date"]')
    end

    def end_date_input
      f('input[data-row-key="end-date"]')
    end

    def close_date_input
      f('input[data-row-key="close-date"]')
    end

    def weight_input
      f('#weight')
    end
    def save_period_button
      f('button[aria-label="Save Grading Period"]')
    end

    def grading_period_list
      f('.GradingPeriodList')
    end

    def period_css
      '.GradingPeriodList__period span'
    end

    def period_delete_button
      f(".GradingPeriodList button[title='Delete New Period']")
    end

    def period_edit_button
      f(".GradingPeriodList button[title='Edit New Period']")
    end

    def visit(account_id)
      get "/accounts/#{account_id}/grading_standards"
    end

    def add_grading_period_set(name: "Grading Period Set 1", term: nil, weighted: nil, show_total: nil)
      add_set_of_grading_periods_button.click
      replace_content(set_name_input, name)
      if term.present? then attach_term_to_set(term) end
      if weighted.present? then weighted_checkbox.click end
      if show_total.present? then show_total_checkbox.click end
      create_set_button.click
    end

    def attach_term_to_set(term)
      term_input.click
      hover_and_click("div:contains(#{term})")
    end

    def show_total_checked?
      edit_grading_period_set_button.click
      show_total_checkbox_checked?
    end

    def delete_first_grading_period_set(are_you_sure)
      delete_grading_period_set_button.click
      alert = driver.switch_to.alert
      if are_you_sure
        alert.accept
      else
        alert.dismiss
      end
      wait_for_ajaximations
    end

    def edit_first_grading_period_set(new_name)
      edit_grading_period_set_button.click
      replace_content(set_name_input, new_name)
      edit_set_save_button.click
    end

    def add_grading_period(title="Grading Period 1")
      expand_first_set
      add_grading_period_link.click
      replace_content(period_title_input, title)
      replace_content(start_date_input, format_date_for_view(Time.zone.now, :medium))
      replace_content(end_date_input, format_date_for_view(Time.zone.now + 1.month, :medium))
      save_period_button.click
    end

    def weight_field_in_grading_period?
      add_grading_period_link.click
      weight_input.displayed?
    end

    def expand_first_set
      first_collapsed_set.click
    end

    def open_grading_period_form
      period_edit_button.click
    end

    def close_date_value
      close_date_input.attribute("value")
    end

    def end_date_value
      end_date_input.attribute("value")
    end

    def edit_first_grading_period(title)
      expand_first_set
      open_grading_period_form
      replace_content(period_title_input, title)
      save_period_button.click
    end

    def select_term_filter(term)
      click_option(".EnrollmentTerms__dropdown", term)
    end

    def all_collapsed_set_titles
      ff(all_collapsed_set_titles_css)
    end

    def all_sets
      ff(all_sets_css)
    end

    def find_set(set_name)
      all_sets.each do |title|
        if title.text == set_name then return title end
      end
      return nil
    end

    def grading_period_set_displayed?(set_name)
      set = find_set(set_name)
      if set.nil?
        return false
      else
        return set.displayed?
      end
    end

    def all_periods
      ff(period_css)
    end

    def find_period(period_name)
      all_periods.each do |period|
        if period.text == period_name then return period end
      end
      return nil
    end

    def add_grading_period_link_displayed?
      link = add_grading_period_link
      if link.nil?
        return false
      else
        link.displayed?
      end
    end

    def grading_period_displayed?(period_name)
      period = find_period(period_name)
      if period.nil?
        return false
      else
        period.displayed?
      end
    end

    def delete_first_grading_period(are_you_sure)
      period_delete_button.click
      alert = driver.switch_to.alert
      if are_you_sure
        alert.accept
      else
        alert.dismiss
      end
    end

    def search_grading_periods(search_term)
      replace_content(search_box, search_term)
      sleep 1 # InputFilter has a delay
    end
  end
end

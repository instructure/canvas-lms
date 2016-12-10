module GradingStandards
  class MultipleGradingPeriods
    include SeleniumDriverSetup
    include OtherHelperMethods
    include CustomSeleniumActions
    include CustomAlertActions
    include CustomPageLoaders
    include CustomScreenActions
    include CustomValidators
    include CustomWaitMethods
    include CustomDateHelpers
    include LoginAndSessionMethods
    include SeleniumErrorRecovery

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
      f('.GradingPeriodList .icon-trash')
    end

    def period_edit_button
      f('.GradingPeriodList .icon-edit')
    end

    def visit(account_id)
      get "/accounts/#{account_id}/grading_standards"
    end

    def add_grading_period_set(name = "Grading Period Set 1", term = nil)
      add_set_of_grading_periods_button.click
      replace_content(set_name_input, name)
      if term.present? then attach_term_to_set(term) end
      create_set_button.click
    end

    def attach_term_to_set(term)
      term_input.click
      hover_and_click("div:contains(#{term})")
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

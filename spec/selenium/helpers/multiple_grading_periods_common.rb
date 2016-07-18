module MultipleGradingPeriods
  module AccountPage
    shared_context "account_page_components" do
      # Helpers
      let(:backend_group_helper) { Factories::GradingPeriodGroupHelper.new }
      let(:backend_period_helper) { Factories::GradingPeriodHelper.new }

      # Main page components
      let(:grading_periods_tab) { f("#grading-periods-tab") }
      let(:add_set_of_grading_periods_button) { f('button[aria-label="Add Set of Grading Periods"]') }
      let(:term_dropdown) { f('select[aria-label="Enrollment Term"]')}
      let(:search_box) { f('.GradingPeriodSearchField input')}

      # Set components
      let(:set_name_input) { f('#set-name')}
      let(:term_input) { f('input[aria-label^="Start typing to search."]') }
      let(:create_set_button) { fj('button:contains("Create")') }
      let(:grading_period_set_title_css) { ".GradingPeriodSet__title" }
      let(:set_title) { f(grading_period_set_title_css) }
      let(:add_grading_period_link) { f('button[aria-label="Add Grading Period"]') }
      let(:delete_grading_period_set_button) { f('#grading-period-sets button[title^="Delete "]') }
      let(:edit_grading_period_set_button) { f('#grading-period-sets button[title^="Edit "]')}
      let(:edit_set_save_button) { f('button[aria-label="Save Grading Period Set"]') }
      let(:first_collapsed_set) { f('.GradingPeriodSet--collapsed') }
      let(:all_sets_css) { '.GradingPeriodSet__title'}


      # Period components
      let(:period_title_input) { f('#title') }
      let(:start_date_input) { f('input[data-row-key="start-date"]') }
      let(:end_date_input) { f('input[data-row-key="end-date"]') }
      let(:close_date_input) { f('input[data-row-key="close-date"]') }
      let(:save_period_button) { f('button[aria-label="Save Grading Period"]') }
      let(:grading_period_list) { f('.GradingPeriodList') }
      let(:period_css) { '.GradingPeriodList__period span' }
      let(:period_delete_button) { f('.GradingPeriodList .icon-trash') }
      let(:period_edit_button) { f('.GradingPeriodList .icon-edit') }
    end

    def visit_account_grading_standards(account_id)
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

    def edit_first_grading_period(title)
      expand_first_set
      period_edit_button.click
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

    def all_periods
      ff(period_css)
    end

    def find_period(period_name)
      all_periods.each do |period|
        if period.text == period_name then return period end
      end
      return nil
    end

    def delete_first_grading_period(are_you_sure)
      expand_first_set
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

  module StudentPage
    shared_context "student_page_components" do
      # Helpers
      let(:backend_group_helper) { Factories::GradingPeriodGroupHelper.new }
      let(:backend_period_helper) { Factories::GradingPeriodHelper.new }

      # Period components
      let(:period_options_css) { '.grading_periods_selector > option' }

      # Assignment components
      let(:assignment_titles_css) { '.student_assignment > th > a'}
    end

    def visit_student_grades_page(course, student)
      get "/courses/#{course.id}/grades/#{student.id}"
    end

    def select_period_by_name(name)
      period = ff(period_options_css).find do |option|
        option.text == name
      end
      period.click
    end

    def assignment_titles
      ff(assignment_titles_css).map do |option|
        option.text
      end
    end
  end
end

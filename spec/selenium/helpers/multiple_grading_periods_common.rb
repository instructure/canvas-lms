module MultipleGradingPeriods
  module AccountPage
    shared_context "account_page_components" do
      # Helpers
      let(:group_helper) { Factories::GradingPeriodGroupHelper.new }
      let(:period_helper) { Factories::GradingPeriodHelper.new }

      # Main page components
      let(:grading_periods_tab) { f("#grading-periods-tab") }
      let(:add_set_of_grading_periods_button) { f('button[aria-label="Add Set of Grading Periods"]') }
      let(:term_dropdown) { f('select[aria-label="Enrollment Term"]')}

      # Set components
      let(:set_name_input) { f('#set-name')}
      let(:term_input) { f('input[aria-label^="Start typing to search."]') }
      let(:create_set_button) { fj('button:contains("Create")') }
      let(:grading_period_set_title_css) { ".GradingPeriodSet__title" }
      let(:set_title) { f(grading_period_set_title_css) }
      let(:add_grading_period_link) { f('.GradingPeriodList__new-period__add-button') }
      let(:delete_grading_period_set_button) { f('.delete_grading_period_set_button') }
      let(:edit_grading_period_set_button) { f('.edit_grading_period_set_button')}
      let(:edit_set_save_button) { f('button[aria-label="Save Grading Period Set"]') }
      let(:first_collapsed_set) { f('.GradingPeriodSet--collapsed') }
      let(:all_collapsed_set_titles_css) { '.GradingPeriodSet--collapsed .GradingPeriodSet__title' }


      # Period components
      let(:period_title_input) { f('#title') }
      let(:start_date_input) { f('input[data-row-key="start-date"]') }
      let(:end_date_input) { f('input[data-row-key="end-date"]') }
      let(:close_date_input) { f('input[data-row-key="close-date"]') }
      let(:save_period_button) { f('button[aria-label="Save Grading Period"]')}
      let(:first_period) { f('.GradingPeriodList__period span') }
      let(:period_delete_button) { f('.GradingPeriodList .icon-trash')}
      let(:period_edit_button) { f('.GradingPeriodList .icon-edit')}
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

    def set_present?(title)
      if set_title.present? then set_title.text == title end
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

    def period_present?(title)
      first_period.text == title
    end

    def edit_first_grading_period(title)
      expand_first_set
      period_edit_button.click
      replace_content(period_title_input, title)
      save_period_button.click
    end

    def select_term_filter(term)
      term_dropdown.click
      options = ff('select[aria-label="Enrollment Term"] option')
      options.each do |option|
        if option.text == term then option.click end
      end
    end

    def all_collapsed_set_titles
      ff(all_collapsed_set_titles_css)
    end

    def find_set(set_name)
      all_collapsed_set_titles.each do |title|
        if title.text == set_name then return title end
      end
    end
  end
end

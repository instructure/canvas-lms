module MultipleGradingPeriods
  module AccountPage
    shared_context "account_page_components" do
      let(:grading_periods_tab) { f("#grading-periods-tab") }
      let(:add_set_of_grading_periods_button) { f('button[aria-label="Add Set of Grading Periods"]') }
      let(:set_name_input) { f('#set-name')}
      let(:term_input) { f('input[aria-label^="Start typing to search."]') }
      let(:create_set_button) { fj('button:contains("Create")') }
      let(:grading_period_set_title_css) { ".GradingPeriodSet__title" }
      let(:set_title) { f(grading_period_set_title_css) }
      let(:add_grading_period_link) { f('.GradingPeriodList__new-period__add-button') }
      let(:delete_grading_period_set_button) { f('.delete_grading_period_set_button') }
      let(:edit_grading_period_set_button) { f('.edit_grading_period_set_button')}
      let(:edit_set_save_button) { f('button[aria-label="Save Grading Period Set"]') }
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
  end
end

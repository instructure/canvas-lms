require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/multiple_grading_periods_common')

describe "multiple grading periods account page" do
  include_context "in-process server selenium tests"
  include MultipleGradingPeriods::AccountPage
  include_context "account_page_components"

  context 'with mgp enabled' do
    before(:each) do
      admin_logged_in
      Account.default.enable_feature!(:multiple_grading_periods)
    end

    it "adds grading period set", test_id: 2528622, priority: "1" do
      visit_account_grading_standards(Account.default.id)
      add_grading_period_set("Set Name!", "Default Term")
      expect(set_present?("Set Name!")).to be true
      expect(add_grading_period_link).to be_displayed
    end

    it "deletes grading period set", test_id: 2528621, priority: "1" do
      group = Factories::GradingPeriodGroupHelper.new.create_for_account(Account.default)
      visit_account_grading_standards(Account.default.id)
      delete_first_grading_period_set(false)
      expect(set_present?(group.title)).to be true
      delete_first_grading_period_set(true)
      expect(grading_periods_tab).not_to contain_css(grading_period_set_title_css)
    end

    it "edits grading period set", test_id: 2528628, priority: "1" do
      Factories::GradingPeriodGroupHelper.new.create_for_account(Account.default)
      visit_account_grading_standards(Account.default.id)
      edit_first_grading_period_set("Edited Title")
      expect(set_present?("Edited Title")).to be true

    end
  end
end

